Output docs/macro-files.gif

Require echo

Set Shell "bash"
Set FontSize 20
Set Width 1200
Set Height 600

Type "# This is a menu.sh tutorial." Sleep 500ms
Enter Sleep 1s

Enter Sleep 500ms
Type "# menu.sh is a lightweight launcher for text-mode consoles." Sleep 500ms
Enter Sleep 1s

Enter Sleep 500ms
Type "# https://github.com/iandennismiller/menu.sh" Sleep 500ms
Enter Sleep 1s

Enter Sleep 500ms
Type "# Learn how to use the menu.sh __files__ macro." Sleep 500ms
Enter Sleep 2s

Enter Sleep 500ms
Type "# Dynamically add files from any path to your menu with __files__." Sleep 500ms
Enter Sleep 2s

Enter Sleep 500ms
Type "# Selecting a file in the menu executes __cmd__ with the filename as input." Sleep 500ms
Enter Sleep 2s

Enter Sleep 500ms
Type "# This example will 'cat' the file we select." Sleep 500ms
Enter Sleep 2s

Enter Sleep 500ms
Type "# First we'll look at the menu, which is a YAML file." Sleep 500ms
Enter Sleep 2s

Type "clear" Sleep 500ms
Enter Sleep 500ms

Type "cat ./examples/files.menu.yaml" Sleep 1s
Enter Sleep 4s

Enter Sleep 500ms
Type "# The __files__ macro './**/*.yaml' adds YAML files to the menu." Sleep 500ms
Enter Sleep 2s

Enter Sleep 500ms
Type "# The __cmd__ macro 'cat $1' displays the file selected in the menu." Sleep 500ms
Enter Sleep 2s

Enter Sleep 500ms
Type "# Now let's run this menu." Sleep 500ms
Enter Sleep 2s

Enter Sleep 500ms
Type "./examples/files.menu.yaml" Sleep 1s
Enter Sleep 4s

# press enter on the 'examples'
Enter Sleep 4s

# go down to files.menu.yaml
Down Sleep 1s
Down Sleep 1s

# view the file
Enter Sleep 4s

# exit the file viewer
Enter Sleep 1s

# we are back at the root menu path; go down to quit
Down Sleep 1s 
Down Sleep 1s

# exit the menu
Enter Sleep 2s

Type "# We effectively ran 'cat ./examples/files.menu.yaml'" Sleep 500ms
Enter Sleep 2s

Enter Sleep 500ms
Type "# Let's see that menu file one more time." Sleep 500ms
Enter Sleep 2s

Type "clear" Sleep 500ms
Enter Sleep 500ms

Type "cat ./examples/files.menu.yaml" Sleep 500ms 
Enter Sleep 10s

Enter Sleep 1s
Enter Sleep 1s
Enter Sleep 1s
Type "# That's the end of this menu.sh tutorial." Sleep 500ms
Enter Sleep 2s

Enter Sleep 500ms
Type "# menu.sh is a lightweight launcher for text-mode consoles." Sleep 500ms
Enter Sleep 1s

Enter Sleep 500ms
Type "# https://github.com/iandennismiller/menu.sh" Sleep 500ms
Enter Sleep 10s
