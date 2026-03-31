#!/usr/bin/env bash
set -euo pipefail

# macOS system preferences
#
# Run once after a fresh install, then re-run if preferences change.
# Requires closing System Settings before running — some panes hold locks.
# A logout/restart may be needed for certain settings to take full effect.

echo "Applying macOS preferences..."

# Close System Settings to prevent it from overriding changes
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true
sleep 1

###############################################################################
# Dock                                                                        #
###############################################################################

# Icon size (pixels)
defaults write com.apple.dock tilesize -int 77

# Disable magnification
defaults write com.apple.dock magnification -bool false

# Hide recent applications
defaults write com.apple.dock show-recents -bool false

# Minimize windows into their application icon
defaults write com.apple.dock minimize-to-application -bool true

###############################################################################
# Finder                                                                      #
###############################################################################

# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

###############################################################################
# Keyboard                                                                    #
###############################################################################

# Fast key repeat rate (lower = faster)
defaults write NSGlobalDomain KeyRepeat -int 12

# Short delay before key repeat starts (lower = shorter)
defaults write NSGlobalDomain InitialKeyRepeat -int 30

# Disable press-and-hold for accent characters — enable key repeat instead
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Disable automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart dashes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable period with double-space
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

###############################################################################
# Trackpad                                                                    #
###############################################################################

# Enable tap to click
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# Tracking speed (0.0 to 3.0, default ~1.0)
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 2.0

###############################################################################
# Screenshots                                                                 #
###############################################################################

# Disable floating thumbnail after taking a screenshot
defaults write com.apple.screencapture show-thumbnail -bool false

# Disable window shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

###############################################################################
# Mission Control                                                             #
###############################################################################

# Don't automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# Group windows by application in Mission Control
defaults write com.apple.dock expose-group-apps -bool true

###############################################################################
# Apply changes                                                               #
###############################################################################

killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

echo "Done. Some changes may require a logout/restart to take effect."
