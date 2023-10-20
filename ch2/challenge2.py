#pip install azure-identity
#pip install azure-mgmt-compute
from azure.identity import DefaultAzureCredential
from azure.mgmt.compute import ComputeManagementClient
def main():
    client = ComputeManagementClient(
        credential=DefaultAzureCredential(),
        subscription_id="07a23f8a-2ba9-42fb-9b3d-ec60f448cb05"
    )
    response = client.virtual_machines.get(
        resource_group_name=input("Resource Group: "),
        vm_name=input("VM Name: ")
    )
    print(response)
if __name__ == "__main__":
    main()