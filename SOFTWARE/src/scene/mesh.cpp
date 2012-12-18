/**
 * @file mesh.cpp
 * @brief Mesh class and OBJ loader.
 *
 * @author Eric Butler (edbutler)
 * @author Zeyang Li (zeyangl)
 */

#include "scene/mesh.hpp"
#include "application/opengl.hpp"
#include <iostream>
#include <cstring>
#include <string>
#include <fstream>
#include <sstream>
#include <map>

namespace _462 {

struct TriIndex
{
    int vertex;
    int normal;
    int tcoord;

    bool operator<( const TriIndex& rhs ) const {
        if ( vertex == rhs.vertex ) {
            if ( normal == rhs.normal ) {
                return tcoord < rhs.tcoord;
            } else {
                return normal < rhs.normal;
            }
        } else {
            return vertex < rhs.vertex;
        }
    }
};

struct Face
{
    TriIndex v[3];
};

enum ObjFormat
{
    VERTEX_ONLY = 1 << 0,
    VERTEX_UV = 1 << 1,
    VERTEX_NORMAL = 1 << 2,
    VERTEX_UV_NORMAL = 1 << 3
};

Mesh::Mesh()
{
    has_tcoords = false;
    has_normals = false;
}

Mesh::~Mesh() { }

bool Mesh::load()
{
    std::cout << "Loading mesh from '" << filename << "'..." << std::endl;

    std::string line;
    std::ifstream file( filename.c_str() );

    typedef std::vector< Vector3 > PositionList;
    typedef std::vector< Vector3 > NormalList;
    typedef std::vector< Vector2 > UVList;
    typedef std::vector< Face > FaceList;

    static const char* scan_vertex = "%d";
    static const char* scan_vertex_uv = "%d/%d";
    static const char* scan_vertex_normal = "%d//%d";
    static const char* scan_vertex_uv_normal = "%d/%d/%d";

    TriIndex tri[4];

    FaceList face_list;
    PositionList position_list;
    NormalList normal_list;
    UVList uv_list;

    int line_num = 0;

    std::string token;

    triangles.clear();

    ObjFormat format = VERTEX_ONLY;

    typedef std::map< TriIndex, unsigned int > VertexMap;
    VertexMap vertex_map;

    if ( !file.is_open() ) {
        std::cout << "Error opening file '" << filename << "' for mesh loading.\n";
        return false;
    }

    while ( getline( file, line ) )
    {
        std::stringstream stream( line );
        stream >> token;
        line_num++;

        if ( token == "v" ) {

            Vector3 position;
            stream >> position.x >> position.y >> position.z;

            if ( stream.fail() ) {
                std::cerr << "position syntax error on line " << line_num << std::endl;
                return false;
            }

            position_list.push_back( position );

        } else if ( token == "vn" ) {
            Vector3 normal;
            stream >> normal.x >> normal.y >> normal.z;

            if( stream.fail() ) {
                std::cerr << "normal syntax error on line " << line_num << std::endl;
                return false;
            }
            normal_list.push_back( normal );

        } else if ( token == "vt" ) {

            Vector2 uv;
            stream >> uv.x >> uv.y;

            if ( stream.fail() ) {
                std::cerr << "uv syntax error on line " << line_num << std::endl;
                return false;
            }

            uv_list.push_back( uv );

        } else if ( token == "f" ) {

            std::vector< std::string > face_tokens;
            std::string vert;

            while ( true ) {
                stream >> vert;
                if( stream.fail() )
                    break;
                face_tokens.push_back( vert );
            }

            // if it's the first time parsing a face, figure out the face format
            if ( face_list.size() == 0 ) {
                std::string token = face_tokens[0];

                if ( token.find( "//" ) != std::string::npos ) {
                    format = VERTEX_NORMAL;
                    has_normals = true;
                } else if ( token.find( '/' ) == std::string::npos ) {
                    format = VERTEX_ONLY;
                } else {
                    size_t p1 = token.find( '/' );
                    size_t p2 = token.rfind( '/' );
                    if ( p1 == p2 ) {
                        format = VERTEX_UV;
                        has_tcoords = true;
                    } else {
                        format = VERTEX_UV_NORMAL;
                        has_normals = true;
                        has_tcoords = true;
                    }
                }
            }

            size_t num_vertex;
            num_vertex = face_tokens.size();

            if ( num_vertex > 4 || num_vertex < 3 ) {
                std::cerr << "Syntax error at line " << line_num
                          << ", face has incorrect number of vertices" << std::endl;
                return false;
            }

            for ( size_t i = 0; i < num_vertex; ++i ) {
                switch ( format )
                {
                case VERTEX_ONLY:
                    sscanf( face_tokens[i].c_str(),
                            scan_vertex,
                            &tri[i].vertex );
                    tri[i].normal = 0;
                    tri[i].tcoord = 0;
                    break;

                case VERTEX_UV:
                    sscanf( face_tokens[i].c_str(),
                            scan_vertex_uv,
                            &tri[i].vertex,
                            &tri[i].tcoord );
                    tri[i].normal = 0;
                    break;

                case VERTEX_NORMAL:
                    sscanf( face_tokens[i].c_str(),
                            scan_vertex_normal,
                            &tri[i].vertex,
                            &tri[i].normal );
                    tri[i].tcoord = 0;
                    break;

                case VERTEX_UV_NORMAL:
                    sscanf( face_tokens[i].c_str(),
                            scan_vertex_uv_normal,
                            &tri[i].vertex,
                            &tri[i].tcoord,
                            &tri[i].normal );
                    break;

                default:
                    std::cerr << "Syntax error, unrecongnized face format at line "
                              << line_num << std::endl;
                    break;
                }
            }

            for ( size_t i = 0; i < num_vertex; ++i ) {
                tri[i].vertex--;
                tri[i].normal--;
                tri[i].tcoord--;
            }

            Face f1 = { { tri[0], tri[1], tri[2] } };
            face_list.push_back( f1 );

            if ( num_vertex == 4 ) {
                Face f2 = { { tri[2], tri[3], tri[0] } };
                face_list.push_back( f2 );
            }

        } else if ( token == " " ) {

        } else {
            //std::cerr << "Unknown token on line " << line_num << std::endl;
        }

        token.clear();
        line.clear();
    }

    // verify index list sanity

    int num_vertex = position_list.size();
    int num_normal = normal_list.size();
    int num_tcoord = uv_list.size();

    for ( size_t i = 0; i < face_list.size(); ++i ) {
        const Face& face = face_list[i];
        for ( size_t j = 0; j < 3; ++j ) {
            int vidx = face.v[j].vertex;
            int nidx = face.v[j].normal;
            int tidx = face.v[j].tcoord;

            if (    vidx <  0 || vidx >= num_vertex
                 || nidx < -1 || nidx >= num_normal
                 || tidx < -1 || tidx >= num_tcoord ) {
                std::cout << "Invalid index in face " << i << ".\n";
            }
        }
    }

    // build vertex list using map for shared vertices

    triangles.reserve( face_list.size() );
    vertices.reserve( face_list.size() * 2 );

    // current vertex index, for creating new vertices
    unsigned int vert_idx_counter = 0;

    for ( size_t i = 0; i < face_list.size(); ++i ) {
        const Face& face = face_list[i];
        MeshTriangle tri;
        for ( size_t j = 0; j < 3; ++j ) {
            // two vertices are only actually the same one if the vertex,
            // normal, and tcoord are all the same. use the map to check this.
            std::pair< VertexMap::iterator, bool > rv = vertex_map.insert( std::make_pair( face.v[j], vert_idx_counter ) );
            if ( rv.second ) {
                MeshVertex v;
                v.position = position_list[face.v[j].vertex];
                int nidx = face.v[j].normal;
                v.normal = nidx == -1 ? Vector3::Zero : normal_list[nidx];
                int tidx = face.v[j].tcoord;
                v.tex_coord = tidx == -1 ? Vector2::Zero : uv_list[tidx];
                vertices.push_back( v );
                vert_idx_counter++;
            }

            tri.vertices[j] = rv.first->second;
        }
        triangles.push_back( tri );
    }

    std::cout << "Successfully loaded mesh '" << filename << "'.\n";
    return true;
}

/*
 *  This function creates a collision box mesh based on the min and max coordinates given to it.
 */
void Mesh::create_collision_box(real_t min_x, real_t max_x, real_t min_y, real_t max_y, real_t min_z, real_t max_z)
{
    MeshVertex v[8];
    v[0].position = Vector3(min_x, min_y, min_z);
    v[1].position = Vector3(min_x, min_y, max_z);
    v[2].position = Vector3(min_x, max_y, min_z);
    v[3].position = Vector3(min_x, max_y, max_z);
    v[4].position = Vector3(max_x, min_y, min_z);
    v[5].position = Vector3(max_x, min_y, max_z);
    v[6].position = Vector3(max_x, max_y, min_z);
    v[7].position = Vector3(max_x, max_y, max_z);

    MeshTriangle t[12];
    t[0].vertices[0] = 0;
    t[0].vertices[1] = 1;
    t[0].vertices[2] = 3;

    t[1].vertices[0] = 0;
    t[1].vertices[1] = 2;
    t[1].vertices[2] = 3;

    t[2].vertices[0] = 0;
    t[2].vertices[1] = 1;
    t[2].vertices[2] = 4;

    t[3].vertices[0] = 1;
    t[3].vertices[1] = 4;
    t[3].vertices[2] = 5;

    t[4].vertices[0] = 2;
    t[4].vertices[1] = 4;
    t[4].vertices[2] = 6;

    t[5].vertices[0] = 0;
    t[5].vertices[1] = 2;
    t[5].vertices[2] = 4;

    t[6].vertices[0] = 1;
    t[6].vertices[1] = 3;
    t[6].vertices[2] = 5;

    t[7].vertices[0] = 3;
    t[7].vertices[1] = 5;
    t[7].vertices[2] = 7;

    t[8].vertices[0] = 2;
    t[8].vertices[1] = 3;
    t[8].vertices[2] = 7;

    t[9].vertices[0] = 2;
    t[9].vertices[1] = 6;
    t[9].vertices[2] = 7;

    t[10].vertices[0] = 5;
    t[10].vertices[1] = 6;
    t[10].vertices[2] = 7;

    t[11].vertices[0] = 4;
    t[11].vertices[1] = 5;
    t[11].vertices[2] = 6;

    for(int i=0; i<8; i++)
        vertices.push_back(v[i]);
    for(int i=0; i<12; i++)
        triangles.push_back(t[i]);
}

const MeshTriangle* Mesh::get_triangles() const
{
    return triangles.empty() ? NULL : &triangles[0];
}

size_t Mesh::num_triangles() const
{
    return triangles.size();
}

const MeshVertex* Mesh::get_vertices() const
{
    return vertices.empty() ? NULL : &vertices[0];
}

size_t Mesh::num_vertices() const
{
    return vertices.size();
}

bool Mesh::are_normals_valid() const
{
    return has_normals;
}

bool Mesh::are_tex_coords_valid() const
{
    return has_tcoords;
}

// number of floats per vertex
#define VERTEX_SIZE 8

bool Mesh::create_gl_data()
{
    // if no vertices, nothing to do
    if ( vertices.empty() || triangles.empty() ) {
        return false;
    }

    // compute normals if needed
    if ( !has_normals ) {
        // first zero out
        for ( size_t i = 0; i < vertices.size(); ++i ) {
            vertices[i].normal = Vector3::Zero;
        }

        // then sum in all triangle normals
        for ( size_t i = 0; i < triangles.size(); ++i ) {
            Vector3 pos[3];
            for ( size_t j = 0; j < 3; ++j ) {
                pos[j] = vertices[triangles[i].vertices[j]].position;
            }
            Vector3 normal = normalize( cross( pos[1] - pos[0], pos[2] - pos[0] ) );
            for ( size_t j = 0; j < 3; ++j ) {
                vertices[triangles[i].vertices[j]].normal += normal;
            }
        }

        // then normalize
        for ( size_t i = 0; i < vertices.size(); ++i ) {
            vertices[i].normal = normalize( vertices[i].normal );
        }

        has_normals = true;
    }

    // build vertex data
    vertex_data.resize( vertices.size() * VERTEX_SIZE );
    float* vertex = &vertex_data[0];
    for ( size_t i = 0; i < vertices.size(); ++i ) {
        vertices[i].tex_coord.to_array( vertex + 0 );
        vertices[i].normal.to_array( vertex + 2 );
        vertices[i].position.to_array( vertex + 5 );
        vertex += VERTEX_SIZE;
    }
    // build index data
    index_data.resize( triangles.size() * 3 );
    unsigned int* index = &index_data[0];

    for ( size_t i = 0; i < triangles.size(); ++i ) {
        index[0] = triangles[i].vertices[0];
        index[1] = triangles[i].vertices[1];
        index[2] = triangles[i].vertices[2];
        index += 3;
    }
    return true;
}

void Mesh::render() const
{
    assert( index_data.size() > 0 );
    glInterleavedArrays( GL_T2F_N3F_V3F, VERTEX_SIZE * sizeof vertex_data[0], &vertex_data[0] );
    glDrawElements( GL_TRIANGLES, index_data.size(), GL_UNSIGNED_INT, &index_data[0] );

    // 545
/*    glBegin(GL_LINES);
		const float * vertex = &vertex_data[0];
		const float * p,* n;
    	for(size_t i=0; i<vertices.size(); i++) {
			float ppn[3];
			n = (vertex+2);
			p = (vertex+5);
			ppn[0] = p[0] + n[0];
			ppn[1] = p[1] + n[1];
			ppn[2] = p[2] + n[2];

			glVertex3f(p[0],p[1],p[2]);
			glVertex3f(ppn[0], ppn[1], ppn[2]);
			vertex += VERTEX_SIZE;
		}
    glEnd(); */
}

} /* _462 */
