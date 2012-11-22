function [] = show_screen_dump(in_filename)

fid = fopen(in_filename,'r');
arraySize = str2num(fgetl(fid));
raw_data = str2num(fgetl(fid));
raw_data = reshape(raw_data,arraySize);
fclose(fid);

rows = arraySize(1);
cols = arraySize(2);
colors = arraySize(3);

k2=1;
c2=1;
r2=1;

for k=1:colors
	for c=1:cols
		for r=1:rows
			img_data(r2,c2,k2) = raw_data(r,c,k)/255.0;
			k2 = k2+1;
			if(k2 == colors+1)
				k2=1;
				c2 = c2 + 1;
				if(c2 == cols+1)
					c2 = 1;
					r2 = r2+1;
				end
			end
		end
	end
end

image(img_data)
