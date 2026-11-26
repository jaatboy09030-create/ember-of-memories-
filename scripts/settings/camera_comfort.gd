class_name CameraComfort
extends Resource
## CAMERA COMFORT: one place for how strong the "worn camera" look is. Shared by
## PlayerCamera (motion, shake, exposure) and ScreenEffects (lens, grain).
## 0 switches a feature off, 1 is the designed amount. Accessibility: players prone to
## motion sickness need motion = 0 and shake = 0 (Xbox Accessibility Guideline 117).
##
## How to change it: open settings/camera_comfort.tres in the Inspector.
## A future options menu should edit this resource, then call
## ScreenEffects.apply_comfort() and PlayerCamera.apply_comfort().

## Hand-held drift, footstep bob, turn bank and start/stop sway.
@export_range(0.0, 1.0) var motion := 1.0
## Knocks and impacts (PlayerCamera.add_shake).
@export_range(0.0, 1.0) var shake := 1.0
## Lens bend and edge colour fringe.
@export_range(0.0, 1.0) var lens := 1.0
## Film grain / sensor noise.
@export_range(0.0, 1.0) var grain := 1.0
## Brightness slowly adapts when moving between dark and bright places.
@export var exposure_adapt := true
