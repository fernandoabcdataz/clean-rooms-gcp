from faker import Faker
from faker.providers import DynamicProvider
from Customer import Customer
from Call import Call
import csv
from datetime import datetime, timedelta, time

# Initialize Faker
fake = Faker()

banking_products_provider = DynamicProvider(
     provider_name="banking_products",
     elements=["savings", "insurance", "mortgage", "investment", "personal loan"]
)

def fakeDateTimeThisWeek():
    # Define the time range (07:00 to 21:00)
    start_time = time(hour=7, minute=0)
    end_time = time(hour=21, minute=0)

    # Get the current date and time
    current_datetime = datetime.now()

    # Calculate the start and end datetimes for this week within the time range
    start_datetime = datetime.combine(current_datetime - timedelta(days=current_datetime.weekday()), start_time)
    end_datetime = datetime.combine(current_datetime + timedelta(days=6 - current_datetime.weekday()), end_time)

    # Generate a fake datetime within the specified range
    fake_datetime = fake.date_time_between_dates(datetime_start=start_datetime, datetime_end=end_datetime)

    return fake_datetime

fake.add_provider(banking_products_provider)

# Number of customers to generate for each dataset
required_customers = 100

# Generate unique emails
unique_emails_client_a = [fake.unique.email() for _ in range(90)]
unique_emails_client_b = [fake.unique.email() for _ in range(90)]

# Generate common emails
common_emails = [fake.unique.email() for _ in range(10)]

# Combine unique and common emails
emails_client_a = unique_emails_client_a + common_emails
emails_client_b = unique_emails_client_b + common_emails

# Shuffle the emails to mix common emails within the datasets
fake.random.shuffle(emails_client_a)
fake.random.shuffle(emails_client_b)

# Number of calls per customer
minimum_call_volume_per_customer = 0
maximum_call_volume_per_customer = 7

def generate_data_client_a(emails):
    customer_id = 0
    customers = []
    calls = []
    for email in emails:
        customer = Customer(customer_id, fake.name(), fake.address().replace('\n', ' '), email)
        customers.append(customer)
        for call_id in range(fake.random_int(minimum_call_volume_per_customer, maximum_call_volume_per_customer)):
            call = Call(f"{customer_id}_{call_id}", customer_id, fakeDateTimeThisWeek(), fake.banking_products())
            calls.append(call)
        customer_id += 1
    
    # Write customers to CSV
    with open("client_a_customers.csv", mode='w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=['id', 'name', 'address', 'email'])
        writer.writeheader()
        for customer in customers:
            writer.writerow({'id': customer.id, 'name': customer.name, 'address': customer.address, 'email': customer.email})
    
    # Write calls to CSV
    with open("client_a_calls.csv", mode='w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=['id', 'customer_id', 'call_datetime', 'product'])
        writer.writeheader()
        for call in calls:
            writer.writerow({'id': call.id, 'customer_id': call.customer_id, 'call_datetime': call.call_datetime.strftime('%Y-%m-%d %H:%M:%S'), 'product': call.product})

def generate_data_client_b(emails):
    customer_id = 0
    customers = []
    for email in emails:
        customer = Customer(customer_id, fake.name(), "", email)
        customers.append(customer)
        customer_id += 1
    
    # Write customers to CSV
    with open("client_b_customers.csv", mode='w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=['id', 'name', 'email'])
        writer.writeheader()
        for customer in customers:
            writer.writerow({'id': customer.id, 'name': customer.name, 'email': customer.email})

# Generate datasets
generate_data_client_a(emails_client_a)
generate_data_client_b(emails_client_b)
