@echo off
:: ===== Start Session =====

git remote remove origin 2>nul
git remote add origin git@github.com:petercl8/PET_Machine_Learning_Datamake.git

:: Fetch latest changes from GitHub
git fetch origin

:: Switch to main branch locally
git checkout main

:: Merge remote changes
git pull origin main

echo Repository is up-to-date.