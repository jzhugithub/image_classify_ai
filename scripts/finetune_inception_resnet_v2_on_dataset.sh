#!/bin/bash

################
# Before train #
################
# 1. convert dataset
# modify parameters in 'convert_data.py'
# cd to image_classify_ai
# run: python convert_data.py

# 2. set dataset for model
# modify parameter in 'read_dataset.py'

###############
# Start train #
###############
# modify parameters in '{scripts}/script.sh'
# cd to image_classify_ai/scripts
# run: bash {script}.sh

###################
# Run tensorboard #
###################
# tensorboard --logdir=${MODEL_DIR}
# http://localhost:6006


# Where the dataset is saved to.
DATASET_DIR=/home/zj/database_temp/ai_challenger_scene/tfrecord

# Where the pre-trained inception_resnet_v2 checkpoint is saved to.
PRETRAINED_CHECKPOINT_PATH=/home/zj/database_temp/inception_resnet_v2_2016_08_30/inception_resnet_v2_2016_08_30.ckpt

# Where the checkpoint and logs will be saved to.
MODEL_DIR=/home/zj/my_workspace/image_classify_ai/models/inception_resnet_v2

# Where the training (fine-tuned) checkpoint and logs will be saved to.
TRAIN_DIR=${MODEL_DIR}/train

# Where the evaluation logs will be saved to.
EVAL_DIR=${MODEL_DIR}/eval

# make dictionary to use.
mkdir -p ${TRAIN_DIR}/stage_1
mkdir -p ${EVAL_DIR}/stage_1
mkdir -p ${TRAIN_DIR}/stage_2
mkdir -p ${EVAL_DIR}/stage_2
mkdir -p ${TRAIN_DIR}/stage_3
mkdir -p ${EVAL_DIR}/stage_3


#### stage_1 ####
# Fine-tune only the new layers for 9000 steps.
python ../train_classifier.py \
  --train_dir=${TRAIN_DIR}/stage_1 \
  --dataset_split_name=train \
  --dataset_dir=${DATASET_DIR} \
  --model_name=inception_resnet_v2 \
  --checkpoint_path=${PRETRAINED_CHECKPOINT_PATH} \
  --checkpoint_exclude_scopes='InceptionResnetV2/AuxLogits, InceptionResnetV2/Logits' \
  --trainable_scopes='InceptionResnetV2/AuxLogits, InceptionResnetV2/Logits' \
  --max_number_of_steps=9000 \
  --batch_size=32 \
  --learning_rate=0.01 \
  --save_interval_secs=500 \
  --save_summaries_secs=120 \
  --log_every_n_steps=100 \
  --optimizer=rmsprop \
  --weight_decay=0.00004

# Run evaluation.
python ../eval_classifier.py \
  --batch_size=10 \
  --checkpoint_path=${TRAIN_DIR}/stage_1 \
  --eval_dir=${EVAL_DIR}/stage_1 \
  --dataset_split_name=validation \
  --dataset_dir=${DATASET_DIR} \
  --model_name=inception_resnet_v2 \


#### stage_2 ####
# Fine-tune all the new layers for 4000 steps.
python ../train_classifier.py \
  --train_dir=${TRAIN_DIR}/stage_2 \
  --dataset_split_name=train \
  --dataset_dir=${DATASET_DIR} \
  --checkpoint_path=${TRAIN_DIR}/stage_1 \
  --model_name=inception_resnet_v2 \
  --max_number_of_steps=4000 \
  --batch_size=32 \
  --learning_rate=0.001 \
  --save_interval_secs=500 \
  --save_summaries_secs=120 \
  --log_every_n_steps=100 \
  --optimizer=rmsprop \
  --weight_decay=0.00004

# Run evaluation.
python ../eval_classifier.py \
  --batch_size=10 \
  --checkpoint_path=${TRAIN_DIR}/stage_2 \
  --eval_dir=${EVAL_DIR}/stage_2 \
  --dataset_split_name=validation \
  --dataset_dir=${DATASET_DIR} \
  --model_name=inception_resnet_v2


#### stage_3 ####
# Fine-tune all the new layers for 4000 steps.
python ../train_classifier.py \
  --train_dir=${TRAIN_DIR}/stage_3 \
  --dataset_split_name=train \
  --dataset_dir=${DATASET_DIR} \
  --checkpoint_path=${TRAIN_DIR}/stage_2 \
  --model_name=inception_resnet_v2 \
  --max_number_of_steps=4000 \
  --batch_size=32 \
  --learning_rate=0.0009 \
  --save_interval_secs=500 \
  --save_summaries_secs=120 \
  --log_every_n_steps=100 \
  --optimizer=rmsprop \
  --weight_decay=0.00004

# Run evaluation.
python ../eval_classifier.py \
  --batch_size=10 \
  --checkpoint_path=${TRAIN_DIR}/stage_3 \
  --eval_dir=${EVAL_DIR}/stage_3 \
  --dataset_split_name=validation \
  --dataset_dir=${DATASET_DIR} \
  --model_name=inception_resnet_v2


# Run test.
python ../test_classifier.py \
    --checkpoint_path=${TRAIN_DIR}/stage_3 \
    --output_path=/home/zj/my_workspace/image_classify_ai/result/submit_10_02_test_1.json \
    --test_path=/home/zj/database_temp/ai_challenger_scene/ai_challenger_scene_test_a_20170922/scene_test_a_images_20170922 \
    --num_classes=80 \
    --model_name=inception_resnet_v2
