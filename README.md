# obsidian-pusherman

Running pusherman-install.sh adds a pre-push hook to a specified local git repository. The hook opens a text editor (vim by default) and let's you make some notes about the push.

These notes are stored locally as .md files, with the main intention being tha that you are storing them in Obsidian - although that doesn't have to be the case.

When you define the directory where you want the notes, that directory will be where notes are stored. 

Each push will have it's own directory beneath that main directory, with the name being the name of your local feature branch. 