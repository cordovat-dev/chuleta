# Chuleta
This command-line utility for Linux/Unix facilitates the quick search, preview, and modification of text-based cheat-sheets. It leverages a folder structure as the entry point for topics and generates topic completion. Powered by a full-text search SQLite database, it also features Bash autocompletion for topics and terms to streamline the search process.

## Philosophy

Text files are the most universal file format, and the Linux command line is where many problems are solved. I wanted to have all my cheat-sheets at my fingertips with a Linux CLI application that indexes plain text file cheat-sheets, allowing for keyword and topic searches without the need for a mouse. This application can either display the results directly in the terminal or open them in the default graphical text editor.

I believe that even the most complex cheat-sheets, code snippets, and annotations can be effectively managed with plain text. Complex procedures can be understood through text-based examples. Therefore, Chuleta indexes a hierarchical directory tree of plain text files, enabling efficient searches for topics and keywords.

## Structure of cheat-sheets folder

Cheat-sheets are stored in a directory tree starting from a base directory containing sub-directories (called topics and subtopics). Each directory contains cheat-sheet files (chuletas) that are plain text files that adhere to a name convention explained bellow.

## Directory name convention

1. lower case
2. No spaces
3: Valid characters: [.a-z0-9/_-]

## Filename convention

Feel free to fork this project to support a different name convention

1. Starts with "chuleta_"
2. Ends with ".txt"
3. No spaces
4. Valid characters: [.A-Za-z0-9/_-]
