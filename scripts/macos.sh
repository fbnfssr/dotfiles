#!/usr/bin/env bash
set -euo pipefail

# macOS system preferences
#
# Run once after a fresh install, then re-run if preferences change.
# Only settings that differ from the macOS defaults are listed: a setting left
# at its default is deliberately absent, not forgotten.
# Requires closing System Settings before running — some panes hold locks.
# A logout/restart may be needed for certain settings to take full effect.
#
# Not scriptable reliably, set by hand: Dock app list, menu bar items
# (Bluetooth shown), keyboard layout (French, chosen in Setup Assistant).

echo "Applying macOS preferences..."

# Close System Settings to prevent it from overriding changes
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true
sleep 1

###############################################################################
# Appearance                                                                  #
###############################################################################

# Dark mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

###############################################################################
# Dock                                                                        #
###############################################################################

# Icon size (pixels)
defaults write com.apple.dock tilesize -int 77

# Disable magnification
defaults write com.apple.dock magnification -bool false

# Hide recent applications
defaults write com.apple.dock show-recents -bool false

# Bottom-right hot corner: no action (the default opens Quick Note)
defaults write com.apple.dock wvous-br-corner -int 1
defaults write com.apple.dock wvous-br-modifier -int 0

###############################################################################
# Finder                                                                      #
###############################################################################

# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# New Finder windows open on the Desktop
defaults write com.apple.finder NewWindowTarget -string "PfDe"

# Set default Finder view to "Icon"
defaults write com.apple.finder FXPreferredViewStyle icnv

# Set default grouping by "Kind"
defaults write com.apple.finder FXPreferredGroupBy Kind

###############################################################################
# Desktop & window management                                                 #
###############################################################################

# Enable Stage Manager
defaults write com.apple.WindowManager GloballyEnabled -bool true

# Hide desktop items, both with and without Stage Manager
defaults write com.apple.WindowManager HideDesktop -bool true
defaults write com.apple.WindowManager StandardHideDesktopIcons -bool true

# Disable built-in window tiling (Rectangle handles it)
defaults write com.apple.WindowManager EnableTilingByEdgeDrag -bool false
defaults write com.apple.WindowManager EnableTopTilingByEdgeDrag -bool false
defaults write com.apple.WindowManager EnableTilingOptionAccelerator -bool false
defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false

###############################################################################
# Keyboard                                                                    #
###############################################################################

# Fast key repeat rate (lower = faster)
defaults write NSGlobalDomain KeyRepeat -int 2

# Short delay before key repeat starts (lower = shorter)
defaults write NSGlobalDomain InitialKeyRepeat -int 25

###############################################################################
# Trackpad & mouse                                                            #
###############################################################################

# Enable tap to click (the -currentHost key also covers the login screen)
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Tracking speed (0.0 to 3.0, default ~1.0)
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 2.0

# Trackpad scrolling speed
defaults write NSGlobalDomain com.apple.trackpad.scrolling -float 0.5882

# Mouse scrolling speed
defaults write NSGlobalDomain com.apple.scrollwheel.scaling -float 0.4412

###############################################################################
# Apply changes                                                               #
###############################################################################

killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

echo "Done. Some changes may require a logout/restart to take effect."
