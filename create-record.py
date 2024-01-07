import boto3
from boto3.session import Session
import random
import string
import argparse
from botocore.exceptions import ClientError

def create_application_subdomain(ip_address):
    """
    Creates an A record with a subdomain in the format 'applicationXXXXX' for the given IP address in AWS Route 53 using a specified AWS profile.

    :param ip_address: The IP address for the A record.
    :param domain: The domain under which the subdomain will be created.
    :param hosted_zone_id: The ID of the hosted zone in AWS Route 53.
    :param aws_profile: The AWS profile to use.
    :return: The name of the created subdomain.
    """
    domain = "pcgamingbuilder.com"
    # Generate a random ID and prepend 'application'
    random_id = ''.join(random.choices(string.ascii_lowercase + string.digits, k=5))
    subdomain = f"application{random_id}"

    # Combine to form the full domain name
    full_domain_name = f"{subdomain}.{domain}"
    # Initialize a boto3 client for Route 53 using the session
    client = boto3.client('route53')

    try:
        response = client.change_resource_record_sets(
            HostedZoneId='Z073250327MWUST5QNDHT',
            ChangeBatch={
                'Changes': [{
                    'Action': 'CREATE',
                    'ResourceRecordSet': {
                        'Name': subdomain,
                        'Type': 'A',
                        'TTL': 300,
                        'ResourceRecords': [{'Value': ip_address}]
                    }
                }]
            }
        )
        print(f"Record created: {full_domain_name} -> {ip_address}")
    except ClientError as e:
        print(f"An error occurred: {e}")
        return None

    return full_domain_name

# Example usage
# ip_address = "192.168.1.1"
# domain = "example.com"
# hosted_zone_id = "ZXXXXXXXXXXXXX"  # Replace with your Hosted Zone ID
# aws_profile = "your-profile-name"  # Replace with your AWS profile name
# create_random_subdomain(ip_address, domain, hosted_zone_id, aws_profile)


def main():
    parser = argparse.ArgumentParser(description='Replace values in a .ts file.')
    parser.add_argument('ip_address', type=str, help='IP address')

    args = parser.parse_args()
    print(args.ip_address)

    return create_application_subdomain(args.ip_address)

if __name__ == '__main__':
    main()