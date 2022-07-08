import os 
#os.environ["CUDA_VISIBLE_DEVICES"] = "0"
import numpy as np
from keras.models import *
from keras import backend as keras
from tensorflow.keras.models import *
import cv2
from PIL import Image
import numpy as np
from patchify import patchify, unpatchify
from tensorflow.keras.utils import normalize

def recon_im(patches: np.ndarray, im_h: int, im_w: int, n_channels: int, stride: int):

    patch_size = patches.shape[1]  # patches assumed to be square

    # Assign output image shape based on patch sizes
    rows = ((im_h - patch_size) // stride) * stride + patch_size
    cols = ((im_w - patch_size) // stride) * stride + patch_size

    if n_channels == 1:
        reconim = np.zeros((rows, cols))
        divim = np.zeros((rows, cols))
    else:
        reconim = np.zeros((rows, cols, n_channels))
        divim = np.zeros((rows, cols, n_channels))

    p_c = (cols - patch_size + stride) / stride  # number of patches needed to fill out a row

    totpatches = patches.shape[0]
    initr, initc = 0, 0

    # extract each patch and place in the zero matrix and sum it with existing pixel values

    reconim[initr:patch_size, initc:patch_size] = patches[0]# fill out top left corner using first patch
    divim[initr:patch_size, initc:patch_size] = np.ones(patches[0].shape)

    patch_num = 1

    while patch_num <= totpatches - 1:
        initc = initc + stride
        reconim[initr:initr + patch_size, initc:patch_size + initc] += patches[patch_num]
        divim[initr:initr + patch_size, initc:patch_size + initc] += np.ones(patches[patch_num].shape)

        if np.remainder(patch_num + 1, p_c) == 0 and patch_num < totpatches - 1:
            initr = initr + stride
            initc = 0
            reconim[initr:initr + patch_size, initc:patch_size] += patches[patch_num + 1]
            divim[initr:initr + patch_size, initc:patch_size] += np.ones(patches[patch_num].shape)
            patch_num += 1
        patch_num += 1
    # Average out pixel values
    reconstructedim = reconim / divim

    return reconstructedim

model = load_model('/content/drive/MyDrive/unet-yeni/unet.hdf5')

large_image = cv2.imread('/content/drive/MyDrive/unet-yeni/Image 12.tif')

step_size = 64

patches = patchify(large_image, (128, 128, 3), step=step_size)  #Step=128 for 128 patches means no overlap

test_patches = np.zeros((patches.shape[0], patches.shape[1], patches.shape[2], 128, 128, 3), np.uint8)

#patches saved in npy file
for i in range(patches.shape[0]):
    for j in range(patches.shape[1]):
        #print(i,j)
        
        single_patch = patches[i, j, 0, :, :, :]
        single_patch = np.array([single_patch])
        test_patches[i, j, 0, :, :, :] = single_patch

#npy file prediction
test_patches = test_patches.astype('float32')
test_patches /= 255
a = patches.shape[0] * patches.shape[1]
test_patches = np.reshape(test_patches, (a,128,128,3))
np.save('/content/drive/MyDrive/unet-yeni/results/test_patches.npy', test_patches)
print("Saving to imgs_big_test.npy files done.")
predicted_test_patches = model.predict(test_patches, batch_size=1, verbose=1)
np.save('/content/drive/MyDrive/unet-yeni/results/predicted_patches.npy', predicted_test_patches)
print("Saving to imgs_big_test.npy files done.")

predicted_test_patches = np.reshape(predicted_test_patches, (a,128,128))
reconstructed_image = recon_im(predicted_test_patches, large_image.shape[0], large_image.shape[1], 1, step_size)

reconstructed_image = cv2.normalize(reconstructed_image, None, 0, 255, cv2.NORM_MINMAX, cv2.CV_8U)
data = Image.fromarray(reconstructed_image)
im1 = Image.Image.split(data)
reconstructed_image = im1[0] #taking blue channel
reconstructed_image.save('/content/drive/MyDrive/unet-yeni/Image12pred2.png')
rec_img = cv2.imread('/content/drive/MyDrive/unet-yeni/Image12pred2.png')
ret, thresh = cv2.threshold(rec_img, 60, 255, cv2.THRESH_BINARY)
b,g,r = cv2.split(thresh)
cv2.imwrite('/content/drive/MyDrive/unet-yeni/Image12binary2.png', b)