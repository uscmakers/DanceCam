import cv2
import numpy as np
from imutils.object_detection import non_max_suppression

# Initialize HOG descriptor and load pre-trained pedestrian detector
hog = cv2.HOGDescriptor()
hog.setSVMDetector(cv2.HOGDescriptor_getDefaultPeopleDetector())

# Open the default camera
cam = cv2.VideoCapture(0)

# Get the default frame width and height
frame_width = int(cam.get(cv2.CAP_PROP_FRAME_WIDTH))
frame_height = int(cam.get(cv2.CAP_PROP_FRAME_HEIGHT))

while True:
    # Read each frame of the video capture
    ret, frame = cam.read()

    # Detect people in the image
    (rects, weights) = hog.detectMultiScale(frame, winStride=(4, 4), padding=(8, 8), scale=1.05)
    
    # Apply non-maxima suppression to the bounding boxes
    rects = np.array([[x, y, x + w, y + h] for (x, y, w, h) in rects])
    nms_rects = non_max_suppression(rects, probs=None, overlapThresh=0.65)

    # Draw the original bounding boxes
    for (xA, yA, xB, yB) in nms_rects:
        cv2.rectangle(frame, (xA, yA), (xB, yB), (0, 255, 0), 2)

    # Display the captured frame
    cv2.imshow('Camera', frame)

    # Press 'q' to exit the loop
    if cv2.waitKey(1) == ord('q'):
        break

# Release the capture and writer objects
cam.release()
cv2.destroyAllWindows()