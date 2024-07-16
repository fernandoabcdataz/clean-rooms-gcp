# Clean Room Data Generation and Infrastructure Setup

This project demonstrates how to generate synthetic customer and call data using Python and Faker, and how to set up the infrastructure to store and query this data on Google Cloud Platform (GCP) using Terraform. The project includes data generation scripts and Terraform configurations for two use cases: CLIENT_A and CLIENT_B.

## Project Structure

- **Data Generation Script:** Generates synthetic customer and call data and exports it to CSV files.
- **Terraform Configuration:** Sets up GCP infrastructure to store and query the generated data.

## Data Generation Script

The script uses the `Faker` library to generate synthetic data. The data includes customer details and call logs for a fictional banking product company (CLIENT_A) and a trading platform (CLIENT_B).

### Script Overview

- **Libraries Used:**
  - `Faker`: To generate fake data.
  - `csv`: To export data to CSV files.
  - `datetime`: To handle date and time operations.

- **Generated Data:**
  - **CLIENT_A:**
    - 100 customers with names, addresses, and emails.
    - Call logs associated with the customers, including call times and banking products discussed.
  - **CLIENT_B:**
    - 100 customers with names and emails.

### Running the Script

1. Ensure you have Python installed.
2. Install the required libraries:
    ```bash
    pip install -r requirements.txt
    ```
3. Run the script:
    ```
    python main.py
    ```

### Output Files

- `client_a_customers.csv`: Contains customer details for CLIENT_A.
- `client_a_calls.csv`: Contains call logs for CLIENT_A.
- `client_b_customers.csv`: Contains customer details for CLIENT_B.

## Terraform Configuration

The Terraform configuration sets up the required GCP infrastructure to store and query the generated data. The setup includes enabling necessary APIs, creating BigQuery datasets and tables, and uploading the CSV files to Google Cloud Storage.

### CLIENT_A Terraform Configuration

- **Enable Necessary APIs:** `serviceusage.googleapis.com` and `bigquery.googleapis.com`.
- **BigQuery Dataset:** `client_customer`
- **Google Cloud Storage Bucket:** `clean_room_raw_data`
- **BigQuery Tables:**
  - `customers`: To store customer details.
  - `calls`: To store call logs.
  - `calls_about_products_table`: To store processed call data for sharing.

### CLIENT_B Terraform Configuration

- **Enable Necessary APIs:** `serviceusage.googleapis.com`, `bigquery.googleapis.com`, and `analyticshub.googleapis.com`.
- **BigQuery Dataset:** `client_customer`
- **Google Cloud Storage Bucket:** `clean_room_raw_data`
- **BigQuery Table:**
  - `customers`: To store customer details.

### Running Terraform

1. Ensure you have Terraform installed.
2. Initialize the Terraform configuration:
   ```bash
   terraform init
   ```
3. Apply the Terraform configuration:
    ```
    terraform apply
    ```

### Notes

- Ensure you have the correct permissions set up in your GCP project.
- Update the `var.project_id` in the Terraform scripts to match your GCP project ID.
- Uncomment and configure additional IAM roles as needed for your use case.

## License

This project is licensed under the MIT License.
