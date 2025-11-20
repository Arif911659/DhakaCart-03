#!/bin/bash

# DhakaCart Git Helper Script
# Usage: ./git-help.sh [command]

echo "🛒 DhakaCart Git Helper"
echo "======================"
echo ""

case "$1" in
  "status")
    echo "📊 Current Git Status:"
    git status
    ;;
    
  "safe-start")
    echo "🛡️  Starting safe modification workflow..."
    read -p "Enter branch name (e.g., feature/new-feature): " branch_name
    git checkout -b "$branch_name"
    echo "✅ Created and switched to branch: $branch_name"
    echo "💡 Make your changes now, then use: ./git-help.sh safe-commit"
    ;;
    
  "safe-commit")
    echo "💾 Committing changes safely..."
    git status
    read -p "Enter commit message: " commit_msg
    git add .
    git commit -m "$commit_msg"
    echo "✅ Changes committed!"
    echo "💡 Push with: git push origin $(git branch --show-current)"
    ;;
    
  "revert")
    echo "⏪ Reverting uncommitted changes..."
    git status
    read -p "Are you sure? This will discard all uncommitted changes (y/N): " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
      git checkout -- .
      echo "✅ All uncommitted changes reverted!"
    else
      echo "❌ Revert cancelled"
    fi
    ;;
    
  "undo-commit")
    echo "⏪ Undoing last commit..."
    read -p "Keep changes? (y/N): " keep_changes
    if [ "$keep_changes" = "y" ] || [ "$keep_changes" = "Y" ]; then
      git reset --soft HEAD~1
      echo "✅ Last commit undone, changes kept"
    else
      read -p "⚠️  This will discard changes! Continue? (y/N): " confirm
      if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        git reset --hard HEAD~1
        echo "✅ Last commit undone, changes discarded"
      else
        echo "❌ Operation cancelled"
      fi
    fi
    ;;
    
  "back-to-main")
    echo "🏠 Switching back to main branch..."
    git checkout main
    echo "✅ Now on main branch"
    ;;
    
  "log")
    echo "📜 Recent commit history:"
    git log --oneline --graph -10
    ;;
    
  "diff")
    echo "🔍 Showing uncommitted changes:"
    git diff
    ;;
    
  "help"|*)
    echo "Available commands:"
    echo "  status         - Show current git status"
    echo "  safe-start     - Create a new branch for safe modifications"
    echo "  safe-commit    - Commit changes with a message"
    echo "  revert         - Discard all uncommitted changes"
    echo "  undo-commit    - Undo the last commit"
    echo "  back-to-main   - Switch back to main branch"
    echo "  log            - Show recent commit history"
    echo "  diff           - Show uncommitted changes"
    echo ""
    echo "Examples:"
    echo "  ./git-help.sh safe-start"
    echo "  ./git-help.sh revert"
    echo "  ./git-help.sh status"
    ;;
esac

