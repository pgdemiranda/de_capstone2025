# DataTalks Data Engineering Capstone 2025

# DataTalks Data Engineering Zoomcamp 2025 Capstone

This project is the capstone of the Data Engineering Zoomcamp, organized by DataTalks. It focuses on building an end-to-end Extract, Load, and Transform (ELT) pipeline using data from the Open Data Plan (PDA) of the Agência Nacional de Energia Elétrica (ANEEL), specifically targeting tariff components applied to electric energy in Brazil. The **goal** is to demonstrate my mastery of the entire data engineering lifecycle, from data ingestion and transformation to storage and analysis, showcasing my ability to design and implement scalable, efficient, and reliable data solutions.

## Table of Contents

## <span style="color:red">**Disclaimer for the evaluation of this project**</span>
1. Originally, in the Zoomcamp, lessons were provided using GCP as the public cloud service and Kestra as the orchestrator. However, we used AWS and Apache Airflow as the public cloud and orchestrator, respectively. We made this choice because we believe this project can serve as a portfolio piece for seeking a job as a Data Engineer, and in Brazil (where I reside), the demand for AWS and Apache Airflow skills is higher than for GCP and Kestra.

2. All AWS resources mentioned here are eligible under the Free Tier. However, to run this project on a virtual machine (VM), it is necessary to use a compute resource in the EC2 service that is not included in the Free Tier. I recommend using t3.large, which may result in costs of **0.0867 USD per hour** (price valid for March 20, 2025).

3. AWS offers a wide range of services, and I had to choose between Amazon Athena and Amazon Redshift as the Data Warehouse. I opted for Redshift because it is a service specifically designed for Data Warehousing. Additionally, I was able to experiment with the serverless version using credits provided by AWS along with the Free Tier. Therefore, the opportunity to use a service architected for Data Warehousing, billed based on computational processing, and included in the Free Tier was too good to pass up for this project.

4. Although I mention Airflow for data orchestration, I utilized Astronomer, a service that integrates Apache Airflow with various platforms and simplifies deployment in production. I chose Astronomer specifically for its integration with DBT, which is used in the transformation stage.

## **1.0 Overview**
### **1.1 What is ANEEL?**

The ANEEL, or Agência Nacional de Energia Elétrica (National Electric Energy Agency), is a special regime autarchy linked to the Brazilian Ministry of Mines and Energy, established to regulate the Brazilian electricity sector. It was created through Law No. 9.427/1996 and Decree No. 2.335/1997, beginning its operations in December 1997. 

ANEEL plays a critical role in regulating and overseeing the sector, with responsibilities that include regulating the generation (production), transmission, distribution, and commercialization of electric energy. Additionally, the agency is responsible for monitoring, either directly or through agreements with state agencies, concessions, permits, and electric energy services. 

Other key functions include implementing federal government policies and guidelines related to the exploitation of electric energy and the utilization of hydroelectric potential, setting tariffs, mediating administrative disputes between sector agents and consumers, and promoting the granting of concessions, permits, and authorizations for energy projects and services, as delegated by the Federal Government.

Source: **https://www.gov.br/aneel/pt-br/acesso-a-informacao/institucional/a-aneel**

### **1.2 About its PDA - Plano de Dados Abertos (Open Data Plan)**

The National Electric Energy Agency (ANEEL) established its Plano de Dados Abertos, PDA, or Open Data Plan for 2022-2024 through Ordinance No. 6,785 of October 24, 2022. The PDA serves as a strategic framework for planning and coordinating data disclosure initiatives, aligning with national regulations and the Open Government Partnership (OGP), a multilateral initiative co-founded by Brazil.

Open data refers to publicly accessible, machine-readable information released under open licenses, allowing free use and cross-referencing while requiring proper attribution (as per Decree No. 8,777/2016 and CGINDA Resolution No. 3/2017). ANEEL's data disclosure prioritizes public interest, transparency, efficiency, and effectiveness, incorporating datasets from the 2020-2022 PDA and adopting prioritization criteria from CGINDA's guidelines.

The PDA aims to:

1. Release data in open formats, ensuring transparency and privacy;

2. Encourage civic applications and new business opportunities using open data;

3. Raise public awareness about open data's potential;

4. Improve data quality and timeliness;

5. Foster social oversight and government interoperability;

6. Strengthen transparency and access to public information.

Source: **https://dadosabertos.aneel.gov.br/about**

### **1.3 Project Goals**
- Build a scalable ELT pipeline using Terraform for infrastructure as code.
- Extract and transform ANEEL's tariff data using Apache Airflow and DBT.
- Load the processed data into AWS Red Shift for analysis.
- Create dashboards in Quick View for data visualization and insights.

### **1.4 Dataset**
The dataset in question can be found in the PDA repository at the following link: https://dadosabertos.aneel.gov.br/dataset/componentes-tarifarias. It contains the values of Energy Tariffs (TE) and Distribution System Usage Tariffs (TUSD), resulting from the tariff adjustment processes of electric energy distribution companies. It is a public repository maintained by ANEEL, created on August 25, 2023, and updated weekly, with coverage from 2010 to the present. The data is provided in separate files, one for each year. The file for the current year is updated weekly, requiring weekly downloads and processing. These datasets are available in multiple formats: CSV, TSV, XML, and JSON.

| **Field Name**               | **Data Type**         | **Field Size** | **Description**                                                                                                                                                                                                                   |
|------------------------------|-----------------------|----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| DatGeracaoConjuntoDados      | Date                 | -              | Date of automatic load processing at the time of dataset generation for publication.                                                                                                                                              |
| DscResolucaoHomologatoria    | String               | 200            | Information about the number and date of the Homologatory Resolution.                                                                                                                                                             |
| SigAgente                    | Numeric              | 10             | Abbreviation of the name of Agents regulated by ANEEL*.                                                                                                                                                                           |
| NumCPFCNPJ                   | String               | 14             | CNPJ or CPF** number of the audited agent (organization).                                                                                                                                                                           |
| DatInicioVigencia            | Date                 | -              | Information about the start date of tariff validity.                                                                                                                                                                              |
| DatFimVigencia               | Date                 | -              | Information about the end date of tariff validity.                                                                                                                                                                                |
| DscBaseTarifaria             | String               | 100            | Tariff of Application, Economic Base, and CVA***. The Tariff of Application is used by the distributor for billing consumers, generators, and distributors, as stated in the Homologatory Resolution. The Economic Base and CVA are used strictly for tariff calculations. |
| DscSubGrupoTarifario         | String               | 255            | Grouping of consumer units according to tariff groups: A1 (≥230 kV), A2 (88 kV to 138 kV), A3 (69 kV), A3a (30 kV to 44 kV), A4 (2.3 kV to 25 kV), AS (underground), B1 (residential), B2 (rural), B3 (other classes), B4 (public lighting). |
| DscModalidadeTarifaria       | String               | 255            | Set of tariffs applicable to energy consumption and demand components, as defined by Normative Resolution No. 1000/2021: conventional; time-based (green and blue), white, prepaid, generation, and distribution.                  |
| DscClasseConsumidor          | String               | 255            | Classification of consumer units according to the purpose of energy use: residential; rural; public lighting; and not applicable (industrial; commerce, services, and others; public power; public service; and self-consumption). |
| DscSubClasseConsumidor       | String               | 255            | Classification of consumer units as a subdivision of classes, according to the purpose of energy use.
| DscDetalheConsumidor         | String               | 255            | Complementary set of variables used in defining tariffs based on application criteria or the universe of eligible consumers.                                                                                                       |
| DscPostoTarifario            | String               | 255            | Identification of the tariff period, defined as hourly intervals for differentiated tariff application throughout the day, as per Normative Resolution No. 1000/2021.                                                              |
| DscUnidade                   | String               | 5              | Tariff unit, according to the applicable electrical quantity, which can be R$/kW and R$/MWh for TUSD and R$/MWh for TE.                                                                                                           |
| SigAgenteAcessante           | String               | 20             | Applicable in cases of nominal tariffs, specifically applicable to a user (distributor, consumer unit, or generator). The abbreviation is as registered in ANEEL's agent registry. Example: AmE, CEMIG-D, EMT, DCELT, CERFOX, etc. |
| DscComponenteTarifario       | String               | 100            | Description of the tariff component as defined in Module 7 of PRORET: "Components of the Tariff for Use of the Distribution System - TUSD (Tarifas de Uso do Sistema de Distribuição) and the Energy Tariff - TE (Tarifas de Energia)."                                                              |
| VlrComponenteTarifario       | Numeric (18,9)       | -              | Presents the value of the TE and TUSD components according to DscUnidade.                                                                                                                                                         |

    * The Agents from ANEEL can be find in this dataset: https://dadosabertos.aneel.gov.br/datastore/dump/64250fc9-4f7a-4d97-b0d4-3c090e005e1c?bom=True

    ** The CPF is a unique ID number for individuals in Brazil. It’s like a Social Security Number (SSN) in the U.S. or a National Insurance Number in the UK. The CNPJ is a unique ID number for companies and organizations in Brazil. It’s like an Employer Identification Number (EIN) in the U.S. or a Company Registration Number in other countries. 

    *** CVA is the records the of the variation, between annual tariff adjustments, of some cost items for distribution companies, such as the purchase of electric energy plant and certain tariff charges in the electric sector.

[Data Dictionary, version 1.0, created in August 25, 2023](https://dadosabertos.aneel.gov.br/dataset/613e6b74-1a4b-4c48-a231-096815e96bd5/resource/cb1d06a8-5b4c-45a0-bb41-9e9546cc578b/download/dm-componentes-tarifarias.pdf)

## **3.0 How to Reproduce This Project**
### **3.1 Requirements and Tools Used**
- AWS (IAM, S3, Redshift)
- Docker
- Terraform
- Apache Airflow/Astronomer
- DBT Core
- Python
- SQL

### **3.2 Steps**

1. **Clone this repository**;

2. **Create a new IAM user**:
    - Go to the AWS Management Console and navigate to IAM > Users.
    - Create a new user and assign the necessary permissions (e.g., AmazonS3FullAccess, AmazonRedshiftFullAccess, etc.).
    - Generate an Access Key for the user and securely store the Access Key ID and Secret Access Key.

3. Set up the **infrastructure using Terraform**;
    - Navigate to the `iac` folder;
    - Create a `terraform.tfvars` file and populate it with the following variables, replacing the placeholders with your **Access Key ID** and **Secret Access Key**:

    ``` hcl
    region                      = "us-east-1"
    s3_bucket_name              = "bucket-aneel"
    redshift_namespace_name     = "aneel"
    redshift_workgroup_name     = "aneel"
    redshift_admin_username     = "admin"
    aws_access_key              = "<aws access key>"
    aws_secret_key              = "<aws secret key>"
    ```

    - Initialize and apply the Terraform configuration:

    ``` bash
    terraform init
    terraform plan
    terraform apply -auto-approve
    ```

4. Run the Apache Airflow pipelines to extract and transform the data.
    - `curl -sSL install.astronomer.io | sudo bash`

    - `astro dev start`

    - `sudo chmod -R 777 .`

    Se nesse momento os conteiners não começarem por alguma razão ligada ao postgres, é um problema de permissão e que deve ser resolvida ou o comando pode ser rodado como usuário root `sudo astro dev start`.

    

5. Explore the data in Redshift and Quicksight.

## **6.0 AWS - Amazon Web Services**
- IAM

- S3

- Amazon Redshift

## **7.0 Infrastructure As a Code - Terraform**

## **8.0 Orchestration - Airflow/Astronomer**

## **9.0 Transformation - DBT/Cosmos**

## **10.0 Data Warehouse - Amazon Redshift**

## **11.0 Data Visualization - Amazon QuickSight**

## **12.0 Conclusion and Next Steps**



-------------------------------------------------------------------------------------------------------



sudo chmod -R 777 .

## DBT
pip install dbt-core dbt-bigquery

dbt clean
dbt deps
dbt compile

- Adicionar isso no DOckerfile?

RUN python -m venv dbt_venv && source dbt_venv/bin/activate && \
    pip install --no-cache-dir dbt-bigquery && deactivate

instalar o pacote dbt utils -> dbt deps