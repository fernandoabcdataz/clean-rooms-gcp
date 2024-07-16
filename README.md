# data-clean-room-example
Experiments with GCP data clean rooms

## data-generator
The Python script generates the following files:
 - iag_customera: a list of random customers containing the fields id, name, address, email. There are 90 unique emails and 10 common email - that intersect with trademe file.
 - iag_calls: a list 

 - trademe_customera: a list of random customers containing the fields id, name, email. There are 90 unique emails and 10 common email - that intersect with iag file.

Run this script following the steps:
1. python
2. python3 main.py

## infra-client/iag
Here you need to have two different GCP accounts

## infra-client/iag
Here, you will be prompted about your GCP data contributor account

1. Create a new Service Account and assign the following roles:

2. Run this script following the steps:
 - terraform init
 - terraform plan
 - terraform apply

3. Access Google Cloud Console and create a new Clean Room

4. Add the table ... to the Clean Room:
 - 
 - 
 - 

## infra-client/trademe
Here, you will upload trademe_customers.csv to Cloud Storage, create a BiqQuery dataset, and a federated table reading from the file uploaded.
You will also subscribe to the Clean Room and create a query to join with data shared.

1. Run terraform script to create Cloud Storage, BigQuery dataset and table
 - 

2. Subscribe to Clean Room
 - 
 - 

3. Join datasets using hashemail and get list of common users

