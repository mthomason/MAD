# Developer

## Test Database Passwords

Test passwords are (it's a never on test server):
MySQL: 127.0.0.1, root, root, employees
SQL Server: 192.168.1.224, test, test, AdventureWorks2022

## Common Commands

The following command was used to create the app preview for iOS.

`ffmpeg -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 -i AppPreview-iPhone-6_3.mov -vf "scale=886:1920" -c:v libx264 -r 30 -c:a aac -shortest AppPreview-Final.mp4`

## Set the Simulator Time

`xcrun simctl status_bar booted override --time "9:41" `

