
import io;


n = 50

target_file = io.open("../../results/Golden/tgt-test")
patches_file = io.open("Codrep_Results/" + date + "/codrep-result.txt")

target_lines = target_file.readlines()

matches_found_no_repeat = 0
matches_found_total = 0


for (target_line in target_lines):
    found = false
    for (i : n):
        patch_line = patches_file.readlines
        match = compare (patch_line, target_line)
        if(match):
            matches_found_total += 1
            if(found == false):
                matches_found_no_repeat += 1
            found = true

print("found fixes for " + matches_found_no_repeat + "bugs")
print("found " + matches_found_total + "total fixes")


