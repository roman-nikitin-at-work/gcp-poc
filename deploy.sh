#!/bin/bash
export PROJECT_ID=$(gcloud config get-value core/project 2>/dev/null)
export PROJECT_NAME="lakehouse"
export DATASET_NAME="stage"
export TABLE_NAME="resi_data"
mkdir ./schemas
gsutil cp gs://"$PROJECT_NAME"-metadata/schemas/*.json ./schemas

echo "{" >> ./schemas/"$TABLE_NAME"_template.json
echo "  \"BigQuery Schema\": " >> ./schemas/"$TABLE_NAME"_template.json
cat ./schemas/"$TABLE_NAME".json >> ./schemas/"$TABLE_NAME"_template.json
echo "}" >> ./schemas/"$TABLE_NAME"_template.json

gsutil cp ./schemas/*_template.json gs://"$PROJECT_NAME"-metadata/schemas

#gsutil mb -p $PROJECT_ID -c "Standard" -l "US" -b on gs://"$PROJECT_NAME"-stage
#gsutil mb -p $PROJECT_ID -c "Standard" -l "US" -b on gs://"$PROJECT_NAME"-metadata

bq --location=US mk \
--dataset \
--default_table_expiration 0 \
--description "Staging dataset" \
$PROJECT_ID:$DATASET_NAME

bq mk \
--table \
--expiration 0 \
--description "Residental price data" \
--label data-source:r12 \
$PROJECT_ID:$DATASET_NAME."$TABLE_NAME"_fs \
./schemas/"$TABLE_NAME".json

#bq show  --format=prettyjson $PROJECT_ID:$DATASET_NAME."$TABLE_NAME"_fs

gcloud dataflow jobs run bq-ingest \
--gcs-location gs://dataflow-templates-us-central1/latest/GCS_Text_to_BigQuery \
--region us-central1 --worker-machine-type n1-standard-4 \
--staging-location gs://"$PROJECT_NAME"-metadata/temp-files \
--parameters javascriptTextTransformGcsPath=gs://"$PROJECT_NAME"-metadata/functions/*.js,JSONPath=gs://"$PROJECT_NAME"-metadata/schemas/"$TABLE_NAME"_template.json,javascriptTextTransformFunctionName=transform,outputTable="$PROJECT_ID":"$DATASET_NAME"."$TABLE_NAME"_fs,inputFilePattern=gs://"$PROJECT_NAME"-stage/R12/"$TABLE_NAME".csv,bigQueryLoadingTemporaryDirectory=gs://"$PROJECT_NAME"-metadata/temp-load

