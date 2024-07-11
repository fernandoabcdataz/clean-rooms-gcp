from faker import Faker
from faker.providers import DynamicProvider
from Customer import Customer
from Call import Call
import csv
from datetime import datetime, timedelta, time

banking_products_provider = DynamicProvider(
     provider_name="banking_products",
     elements=["savings", "insurance", "mortgage", "investment", "personal loan"]
)

def fakeDateTimeThisWeek():
    # Initialize Faker
    fake = Faker()

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

fake = Faker()
fake.add_provider(banking_products_provider)

#number of customers to generate
required_customers = 1000

minimum_call_volume_per_customer = 0
maximum_call_volume_per_customer = 7

customer_id = 0
customers = []
calls = []
for customer_id in range(required_customers):
    customers.append(Customer(customer_id,fake.name(), fake.address().replace('\n',' '), fake.email()))
    for call in range(fake.random_int(minimum_call_volume_per_customer,maximum_call_volume_per_customer)):
        calls.append(Call(f"{customer_id}_{call}", 
                     customer_id, 
                     fakeDateTimeThisWeek(),
                     fake.banking_products()
                     )
        )
        print(f"call {call}")
    print(f"customer {customer_id}")

# Specify the fieldnames based on the properties of the Customer class
fieldnames = ['id', 'name', 'address', 'email']

# Write data to CSV file
with open("customers.csv", mode='w', newline='') as file:
    writer = csv.DictWriter(file, fieldnames=fieldnames)

    writer.writeheader()  # Write header row based on fieldnames
    for customer in customers:
        writer.writerow({
            'id': customer.id,
            'name': customer.name,
            'address': customer.address,
            'email': customer.email
        })  # Write each customer as a row in the CSV file


fieldnames = ['id', 'customer_id', 'call_datetime', 'product']

# Write data to CSV file
with open("calls.csv", mode='w', newline='') as file:
    writer = csv.DictWriter(file, fieldnames=fieldnames)

    writer.writeheader()  # Write header row based on fieldnames
    for call in calls:
        writer.writerow({
            'id': call.id,
            'customer_id': call.customer_id,
            'call_datetime': call.call_datetime.strftime('%Y-%m-%d %H:%M:%S'),
            'product': call.product,
        })  # Write each call as a row in the CSV file




