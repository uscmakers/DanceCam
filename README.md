# DanceCam

Dance Cam is a smart robotic dance videographer that uses computer vision to track the dancer's body to always keep them centered in frame. Dance Cam combines an iOS app with an omni-directional vehicle to create a seamless experience for dancers to record semi-professional, dynamic, and cool dance videos. Dance Cam supports any number of dancers; allows custom song selection; moves front, back, left, right, and diagonally; and saves recorded videos directly to the user's camera roll.

## Team

Project Manager: Irith Katiyar 

Team Members: Abby Farhat, Kenny Nguyen, Austin Tsai, Hannah Lee, Joel Etchri, Ruth Thomson

## Boot Instructions

1. Turn on iPhone's hotspot.
2. Power the motors and Raspberry Pi.
   1. To power the motors, turn on the top power bank. If successful, both motor drivers should have a red light turn on. This power bank is battery-powered via 8 AA batteries.
   2. To power the Raspberry Pi, turn on the bottom power bank. If successful, the Raspberry Pi should light up. This power bank is rechargeable.
3. Run our Flask server on Raspberry Pi.
   1. Connect any computer to the hotspot.
   2. Open a terminal and type the following commands.
      1. `ssh dance@pi.local` (password: `irith`)
      2. `cd Desktop`
      3. `python motor-server.py`
4. Run our iOS app on iPhone.
   1. If not already built on phone, open DanceCam-iOS Xcode Workspace (not Xcode Project) on Xcode on a MacBook computer.
   2. Connect the phone to the MacBook computer. On the phone, click trust this computer.
   3. Make sure that Developer Mode is enabled on the phone.
   4. Build the project on the phone. It should fail
   5. Build the project on the phone
5. Carefully place chassis topper on top of chassis plate. Note that the topper only fits onto the plate in one orienation (match the side with the shorter chassis support to the side with the Raspberry Pi micro-USB port). Ensure that all wires, notably the wire powering the Raspberry Pi, are out of the way of the chassis supports.
6. Place the phone in the phone holder and orient the vehicle so the phone screen faces the user.
  1. The phone's front (selfie) camera should be used, so users can see themselves when facing the phone screen.
7. Click the signal button in the iOS app to connect the app to the Raspberry Pi so the vehicle can move based on your body.

## Frequent Errors

* Developer Mode is not enabled on iPhone:
  * Go to Settings > Privacy & Security > Developer Mode.
  * Once toggled, phone must be restarted.
* 
