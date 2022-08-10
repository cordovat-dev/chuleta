# Chuleta
Command line utility for Linux/Unix for quick search, peek and modification of text-based cheat-sheets. It uses a folder structure as topic point of entry and generates topic completion.

## Philosophy

Text files are the most universal file format. The linux command line is the place where many problems are solved. I wanted to have all my cheat-sheets at my fingertips with linux CLI application that indexes plain text files cheat-sheets and allows searching keywords and topics without having to use the mouse, and either prints them on the terminal screen or opens the default graphic text editor. I believe most complex cheat-sheets, code-snippets and annotations can be fully acomplished without any graphics, only with plain text, even complex procedures can be understood with text-based examples. So Chuleta just indexes a hierarchical directory tree with plain files and allows you to search for topics and keywords.

## Structure of cheat-sheets folder

Cheat-sheets are stored in a directory tree starting from a base directory containing sub-directories (called topics and subtopics). Each directory contains cheat-sheet files (chuletas) that are plain text files that adhere to a name convention explained bellow.

## Directory name convention

1. lower case
2. No spaces
3: Valid characters: [A-Za-z0-9-]

## Filename convention

Feel free to fork this project to support a different name convention

1. Starts with "chuleta_"
2. Ends with ".txt"
3. No spaces
4. Valid characters: [.A-Za-z0-9-]
