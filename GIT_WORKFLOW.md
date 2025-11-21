# 🔄 Git Workflow Guide - Safe Modification & Revert

This guide shows you how to safely modify your DhakaCart project and revert changes if errors occur.

## 📋 Table of Contents
1. [Safe Modification Workflow](#safe-modification-workflow)
2. [Reverting Changes](#reverting-changes)
3. [Common Scenarios](#common-scenarios)
4. [Best Practices](#best-practices)

---

## 🛡️ Safe Modification Workflow

### Method 1: Create a Feature Branch (Recommended)

This is the safest way to make changes without affecting your main branch.

```bash
# 1. Create and switch to a new branch
git checkout -b feature/your-feature-name

# Example:
git checkout -b feature/add-user-authentication
# or
git checkout -b fix/cart-bug
```

**Make your changes now...**

```bash
# 2. Check what files you've changed
git status

# 3. See the actual changes
git diff

# 4. Stage your changes
git add .

# 5. Commit with a descriptive message
git commit -m "Add: User authentication feature"

# 6. Push the branch to GitHub
git push origin feature/your-feature-name
```

**If everything works:**
```bash
# Merge back to main
git checkout main
git merge feature/your-feature-name
git push origin main

# Delete the feature branch (optional)
git branch -d feature/your-feature-name
```

**If there are errors:**
```bash
# Just switch back to main (your changes stay in the branch)
git checkout main

# Or delete the branch if you want to discard changes
git checkout main
git branch -D feature/your-feature-name
```

---

### Method 2: Work on Main Branch (Quick Changes)

If you're making small changes directly on main:

```bash
# 1. Check current status
git status

# 2. Make your changes...

# 3. Before committing, test everything!
docker-compose up -d --build
# Test your changes in browser

# 4. If everything works, commit
git add .
git commit -m "Your change description"
git push origin main
```

---

## ⏪ Reverting Changes

### Scenario 1: Revert Uncommitted Changes (Not Yet Committed)

If you haven't committed yet and want to discard changes:

```bash
# See what files are modified
git status

# Discard changes in a specific file
git checkout -- filename.js

# Discard ALL uncommitted changes (CAREFUL!)
git checkout -- .

# Or use restore (newer Git versions)
git restore .
git restore filename.js
```

### Scenario 2: Revert Last Commit (Keep Changes as Uncommitted)

If you committed but haven't pushed yet:

```bash
# Undo the commit but keep your changes
git reset --soft HEAD~1

# Undo the commit and discard changes (CAREFUL!)
git reset --hard HEAD~1
```

### Scenario 3: Revert Last Commit (Already Pushed to GitHub)

If you already pushed to GitHub:

```bash
# Option A: Create a revert commit (safest, preserves history)
git revert HEAD
git push origin main

# Option B: Reset and force push (use with caution!)
git reset --hard HEAD~1
git push origin main --force
```

⚠️ **Warning**: Force push rewrites history. Only use if you're the only one working on the project!

### Scenario 4: Revert to a Specific Commit

```bash
# Find the commit hash you want to go back to
git log --oneline

# Revert to that commit (creates new commit)
git revert <commit-hash>

# Or reset to that commit (discards later commits)
git reset --hard <commit-hash>
```

### Scenario 5: Revert Specific Files from a Previous Commit

```bash
# Restore a file from a previous commit
git checkout <commit-hash> -- path/to/file.js

# Example: Restore App.js from 3 commits ago
git checkout HEAD~3 -- frontend/src/App.js
```

---

## 🔍 Common Scenarios

### Scenario A: Made Changes, Found Errors, Want to Start Over

```bash
# Discard all uncommitted changes
git checkout -- .

# Or if you want to be more selective
git status  # See what changed
git checkout -- frontend/src/App.js  # Revert specific file
```

### Scenario B: Committed Changes, Found Errors, Haven't Pushed

```bash
# Undo the commit, keep changes to fix
git reset --soft HEAD~1

# Fix the errors, then commit again
git add .
git commit -m "Fixed: Corrected error in feature"
```

### Scenario C: Pushed to GitHub, Found Errors

```bash
# Create a revert commit (recommended)
git revert HEAD
git push origin main

# Or fix the errors and commit a fix
# Make your fixes
git add .
git commit -m "Fix: Corrected error in previous commit"
git push origin main
```

### Scenario D: Want to See What Changed

```bash
# See changes in working directory
git diff

# See changes in a specific file
git diff frontend/src/App.js

# See what changed in last commit
git show HEAD

# See commit history
git log --oneline --graph
```

---

## ✅ Best Practices

### 1. Always Test Before Committing

```bash
# Test your changes
docker-compose up -d --build
# Open browser and test functionality
docker-compose logs -f  # Check for errors
```

### 2. Commit Frequently with Clear Messages

```bash
# Good commit messages
git commit -m "Add: User login functionality"
git commit -m "Fix: Cart total calculation error"
git commit -m "Update: Product images styling"

# Bad commit messages (avoid)
git commit -m "changes"
git commit -m "fix"
```

### 3. Use Branches for Major Changes

```bash
# For new features
git checkout -b feature/new-feature

# For bug fixes
git checkout -b fix/bug-name

# For experiments
git checkout -b experiment/try-something
```

### 4. Keep Main Branch Stable

- Only merge tested, working code to main
- Use branches for development
- Test thoroughly before merging

### 5. Regular Backups

```bash
# Create a backup branch
git branch backup-$(date +%Y%m%d)
git push origin backup-$(date +%Y%m%d)
```

---

## 🚨 Emergency Recovery

If everything goes wrong:

```bash
# 1. Check current status
git status
git log --oneline -10

# 2. Find a good commit to go back to
git log --oneline

# 3. Create a backup branch first
git branch emergency-backup

# 4. Reset to a known good commit
git reset --hard <good-commit-hash>

# 5. Or pull fresh from GitHub
git fetch origin
git reset --hard origin/main
```

---

## 📝 Quick Reference Commands

```bash
# Status & History
git status                    # Current status
git log --oneline            # Commit history
git diff                     # See uncommitted changes

# Reverting
git checkout -- .            # Discard all uncommitted changes
git restore .                # Same as above (newer Git)
git reset --soft HEAD~1      # Undo last commit, keep changes
git reset --hard HEAD~1      # Undo last commit, discard changes
git revert HEAD              # Create revert commit

# Branches
git checkout -b new-branch   # Create and switch to branch
git checkout main            # Switch to main branch
git branch                   # List branches
git branch -d branch-name    # Delete branch

# Stashing (temporary save)
git stash                    # Save uncommitted changes
git stash pop                # Restore stashed changes
git stash list               # List stashes
```

---

## 🎯 Recommended Workflow for Your Project

1. **Before making changes:**
   ```bash
   git checkout -b feature/my-change
   ```

2. **Make your changes**

3. **Test thoroughly:**
   ```bash
   docker-compose up -d --build
   # Test in browser
   ```

4. **If errors occur:**
   ```bash
   git checkout -- .  # Discard changes
   # Or fix the errors
   ```

5. **If everything works:**
   ```bash
   git add .
   git commit -m "Descriptive message"
   git push origin feature/my-change
   git checkout main
   git merge feature/my-change
   git push origin main
   ```

---

## 💡 Pro Tips

1. **Use `git stash`** to temporarily save changes:
   ```bash
   git stash              # Save changes
   git checkout main     # Switch branches
   git stash pop         # Restore changes
   ```

2. **Check before you push:**
   ```bash
   git log origin/main..HEAD  # See commits not yet pushed
   ```

3. **Use descriptive branch names:**
   - ✅ `feature/user-authentication`
   - ✅ `fix/cart-calculation-bug`
   - ❌ `test`
   - ❌ `changes`

---

**Remember**: When in doubt, create a branch! It's always safer to work on a branch than directly on main.

