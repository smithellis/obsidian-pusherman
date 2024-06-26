#!/bin/bash

# Default to the current directory as the Git repository path
default_repo_path=$(pwd)
echo "Enter the full path to your Git repository (default: $default_repo_path):"
read repo_path
repo_path=${repo_path:-$default_repo_path}

# Verify if the specified path is a git repository
if [ ! -d "$repo_path/.git" ]; then
    echo "This does not seem to be a Git repository."
    exit 1
fi

# Get path for storing notes
echo "Enter the full path to the directory where you want to store the notes (default: $default_repo_path/notes):"
read notes_dir
notes_dir=${notes_dir:-"$default_repo_path/notes"}

# Check and create notes directory if it doesn't exist
if [ ! -d "$notes_dir" ]; then
    mkdir -p "$notes_dir"
    if [ $? -ne 0 ]; then
        echo "Failed to create directory at $notes_dir"
        exit 1
    fi
fi

# Path to the pre-push script
hook_path="$repo_path/.git/hooks/pre-push"

# Check if a pre-push hook already exists
if [ -f "$hook_path" ]; then
    echo "A pre-push hook already exists. Choose an action:"
    echo "1) Overwrite the existing hook."
    echo "2) Append to the existing hook."
    echo "3) Exit without modifying the hook."
    read action

    case $action in
        1)
            echo "Overwriting the existing hook..."
            > "$hook_path"  # clear the content before appending
            ;;
        2)
            echo "Appending to the existing hook..."
            echo "" >> "$hook_path" # ensure there's a newline before appending
            ;;
        3)
            echo "Exiting installation."
            exit 0
            ;;
        *)
            echo "Invalid option. Exiting."
            exit 1
            ;;
    esac
fi

# Create or append to the pre-push hook
cat >> "$hook_path" << EOF
#!/bin/bash

# Define your preferred text editor
EDITOR="vim"

# Fetch the current branch name
BRANCH_NAME=\$(git rev-parse --abbrev-ref HEAD)

# Fetch the default branch name
DEFAULT_BRANCH_NAME=\$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)

# Ensure the directory exists
mkdir -p "${notes_dir}"

# Create a directory named after the feature branch, if it doesn't exist
BRANCH_DIR="${notes_dir}/\${BRANCH_NAME}"
mkdir -p "\${BRANCH_DIR}"

# Generate a file name with the date-time stamp
FILE_NAME="\$(date +%Y%m%d_%H%M%S)_push_notes.md"
FILE_PATH="\${BRANCH_DIR}/\${FILE_NAME}"

# Function to fetch commit messages
fetch_commits() {
    # \$1 - name of the remote
    # \$2 - URL of the remote
    echo "Commit details for remote '\$1' with URL '\$2':" > "\${FILE_PATH}"
    echo "" >> "\${FILE_PATH}"

    # Collect commit hashes and messages from commits not yet pushed
    local new_commits=\$(git rev-list HEAD ^\${DEFAULT_BRANCH_NAME})
    if [ -z "\$new_commits" ]; then
        echo "No new commits to push." >> "\${FILE_PATH}"
        return
    fi
    for commit in \$new_commits; do
        echo "## Commit \$commit" >> "\${FILE_PATH}"
        echo "\`\`\`" >> "\${FILE_PATH}"
        git log --format=%B -n 1 \$commit >> "\${FILE_PATH}"
        echo "\`\`\`" >> "\${FILE_PATH"
        echo "" >> "\${FILE_PATH}"
    done
}

# Main logic of the script
if [ "\$#" -ne 0 ]; then
    remote="\$1"
    url="\$2"
    fetch_commits "\$remote" "\$url"
fi

# Check if there are new commits to edit, open the file in the editor
if [ -s "\${FILE_PATH}" ]; then
    vim "\${FILE_PATH}" </dev/tty
else
    echo "No new commits to push. Exiting."
    exit 1
fi

# Allow the push to continue
exit 0
EOF

# Make the hook executable
chmod +x "$hook_path"

echo "The pre-push hook has been installed successfully."
