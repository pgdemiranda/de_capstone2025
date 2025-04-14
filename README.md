# DataTalks Data Engineering Zoomcamp 2025 Capstone

This project is my capstone for the Data Engineering Zoomcamp, organized by DataTalks. I focus on building an end-to-end **Extract, Load, and Transform (ELT)** pipeline using data from the Open Data Plan (PDA) of Brazil’s Agência Nacional de Energia Elétrica (ANEEL), specifically targeting tariff components applied to electric energy. My goal is to demonstrate my proficiency in the entire data engineering lifecycle—from ingestion and transformation to storage and analysis—showcasing my ability to design scalable, efficient, and reliable data solutions.

## Table of Contents

## <span style="color:red">**Disclaimer for the evaluation of this project**</span>
1. **What to install BEFORE running this project**:
    - Docker.
    - Anaconda (you can use other environment and package manager, but **I had problems with Poetry**).
    - Terraform CLI (https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli for instructions).
    - Astronomer CLI (https://www.astronomer.io/docs/astro/cli/install-cli/ for instructions).

2. Orchestration Choice:
    - The Zoomcamp originally used GCP + Kestra for orchestration, but I chose Apache Airflow instead. I made this decision because I believe this project will strengthen my portfolio as a Data Engineer, and in Brazil (where I live), Airflow skills are in higher demand than Kestra.

3. Resource Requirements:
    - All resources I mention qualify under the GCP Free Tier. However, to run this project smoothly on a VM, I recommend an E2 or N2 machine with 8GB RAM.

4. Astronomer Integration:
    - While I reference Airflow for orchestration, I used Astronomer—a service that simplifies Airflow deployment and integrates seamlessly with DBT (my transformation tool). I picked Astronomer specifically for its native DBT support, which streamlines production workflows.

5. Batch Processing Approach:
    - I avoided Apache Spark for batch loading, relying instead on Astronomer + DBT. DBT’s multi-threading capabilities ensure my transformations scale efficiently.

6. Using Windows/Mac:
    - I used Ubuntu Linux to develop and run this project, and naturally most of the instructions are for Linux users.

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

Here's the tabularized version of your field descriptions in English:

| Field Name                  | Data Type          | Size  | Description |
|-----------------------------|--------------------|-------|-------------|
| **DatGeracaoConjuntoDados** | Date               | -     | Date of automatic processing when generating the open dataset for publication. |
| **DscResolucaoHomologatoria** |  String   | 200   | Information about the resolution number and date of the Homologatory Resolution. |
| **SigAgente**               | Numeric            | 10    | Abbreviation representing the name of Agents* regulated by ANEEL. |
| **NumCPFCNPJ**              |  String   | 14    | CNPJ or CPF** number of the audited entity (organization). |
| **DatInicioVigencia**       | Date               | -     | Start date of tariff validity. |
| **DatFimVigencia**          | Date               | -     | End date of tariff validity. |
| **DscBaseTarifaria**        |  String   | 100   | Application Tariff, Economic Base, and CVA. The Application Tariff is used by distributors for billing consumers, generators, and distributors, with values specified in the Homologatory Resolution. The Economic Base Tariff and CVA*** are used strictly for tariff calculations. |
| **DscSubGrupoTarifario**    |  String   | 255   | Grouping of consumer units according to tariff subgroups: A1 (≥230 kV), A2 (88-138 kV), A3 (69 kV), A3a (30-44 kV), A4 (2.3-25 kV), AS (underground), B1 (residential), B2 (rural), B3 (other classes), B4 (public lighting). |
| **DscModalidadeTarifaria**  |  String   | 255   | Set of tariffs applicable to energy consumption and demand components, as defined by Normative Resolution No. 1000/2021: conventional; time-based (green/blue), white, prepaid, generation, and distribution. |
| **DscClasseConsumidor**     |  String   | 255   | Classification of consumer units by energy use purpose (Normative Resolution No. 1000/2021): residential; rural; public lighting; N/A (industrial; commercial/services; government; public service; self-consumption). |
| **DscSubClasseConsumidor**  |  String   | 255   | Subclassification of consumer units as a subdivision of classes. |
| **DscDetalheConsumidor**    |  String   | 255   | Complementary variables used in tariff definitions regarding eligibility criteria. |
| **DscPostoTarifario**       |  String   | 255   | Tariff period identifier (time-based differentiation per Normative Resolution No. 1000/2021). |
| **DscUnidade**              |  String   | 5     | Tariff unit (R$/kW or R$/MWh for TUSD; R$/MWh for TE). |
| **SigAgenteAcessante**      |  String   | 20    | Applicable to nominal tariffs for specific users (distributors/consumers/generators). Abbreviation as registered in ANEEL's agent database (e.g., AmE, CEMIG-D). |
| **DscComponenteTarifario**  |  String   | 100   | Description of tariff components per Module 7 of PRORET: "Components of the Distribution System Usage Tariff (TUSD) and Energy Tariff (TE)." |
| **VlrComponenteTarifario**  | Numeric (18,9)     | -     | Value of TE and TUSD components according to **DscUnidade**. |


    * The Agents from ANEEL can be find in this dataset: https://dadosabertos.aneel.gov.br/datastore/dump/64250fc9-4f7a-4d97-b0d4-3c090e005e1c?bom=True

    ** The CPF is a unique ID number for individuals in Brazil. It’s like a Social Security Number (SSN) in the U.S. or a National Insurance Number in the UK. The CNPJ is a unique ID number for companies and organizations in Brazil. It’s like an Employer Identification Number (EIN) in the U.S. or a Company Registration Number in other countries. 

    *** CVA is the records the of the variation, between annual tariff adjustments, of some cost items for distribution companies, such as the purchase of electric energy plant and certain tariff charges in the electric sector.

[Data Dictionary, version 1.0, created in August 25, 2023](https://dadosabertos.aneel.gov.br/dataset/613e6b74-1a4b-4c48-a231-096815e96bd5/resource/cb1d06a8-5b4c-45a0-bb41-9e9546cc578b/download/dm-componentes-tarifarias.pdf)

## **3.0 How to Reproduce This Project**
### **3.1 Requirements and Tools Used**
- GCP Account
- Docker
- Terraform
- Apache Airflow/Astronomer
- DBT Core
- Anaconda
- Python 3.12

### **3.2 Steps**

1. **Clone this repository**;

2. **Create a GCP Account**;

3. **Create a new Service Account and download the JSON creds**:
    - Go to the IAM & Admin Console and navigate to Service Account.
    - Create a new user and assign the necessary permissions: **BigQuery Admin**, **Storage Admin**;
    - Generate a new Key for the user and store on the folder [**creds**](./creds) and rename it **gcp.json**.

3. Set up the **infrastructure using Terraform**;
    - Navigate to the [**terraform**](./terraform/) folder;
    - Create a `terraform.tfvars` file and populate it, replacing the placeholder with your project ID:

    ```hcl
    credentials = "../creds/gcp.json"
    project = "<project ID>"
    ```

    - Initialize and apply the Terraform configuration:

    ```bash
    terraform init
    terraform plan
    terraform apply -auto-approve
    ```

4. Prepare Python environment, Astronomer and DBT:
    - Navigate to [airflow](./airflow/) folder.
    - Create a `docker-compose.override.yml` file and populate it, replacing the placeholder with the absolute path of your `gcp.json` file from the creds folder:

    ```yml
    services:
    scheduler:
        volumes:
        - <absolute path of your gcp.json file>:rw
    webserver:
        volumes:
        - <absolute path of your gcp.json file>:rw
    triggerer:
        volumes:
        - <absolute path of your gcp.json file>:rw
    ```

    - Create a .env file and populate, replacing the placeholder with the variables needed:

    ```
    GOOGLE_APPLICATION_CREDENTIALS=/usr/local/airflow/gcloud/gcp.json
    GCP_BUCKET=aneel-bucket
    LOCATION=southamerica-east1
    PROJECT_ID=<project id>
    BQ_PROJECT=<project id/bigquery id>
    BQ_DATASET=raw_data
    BQ_TABLE=componente_tarifarias
    ANEEL_DATASET_URL=https://dadosabertos.aneel.gov.br/dataset/613e6b74-1a4b-4c48-a231-096815e96bd5
    ```

    - Start astronomer containers with `astro dev start` (if you are on Linux or Mac, you can have privileges problems, this can be bypassed with `sudo chmod -R 777 .`). On your web browser navigate to localhost:8080/ to confirm that Astronomer is running.
    - Create a new environment with Python 3.12 and install dbt-core and dbt-bigquery packages from [requirements.txt](./requirements.txt)
    - Create a new `profiles.yml` file, replacing the placeholder with the variables needed. You should place this file inside [the project folder](./airflow/dags/dbt/aneel_dw/) or placing it inside `~/.dbt/profiles.yml` location or the appropriate folder if you are a windows user:
    
    ```yml
    aneel_dw:
      outputs:
        dev:
          dataset: data_warehouse
          job_execution_timeout_seconds: 300
          job_retries: 1
          keyfile: <absolute path of your gcp.json file>
          location: SOUTHAMERICA-EAST1
          method: service-account
          priority: interactive
          project: <project id>
          threads: 4
          type: bigquery
      target: dev
    ```

    - Validate the connection still inside of [the project fold](./airflow/dags/dbt/aneel_dw/) with the command `dbt debug`.
    
5. Run the **Apache Airflow** pipelines to extract and transform the data.
    - navigate the `localhost:8080/` on your web browser, login with user **admin** and password **admin**.
    - Manually start `extract_and_load` dag. When finished, start the `load_data_bq` dag.

## **6.0 Google Cloud Plataform**

## **7.0 Infrastructure As a Code - Terraform**

## **8.0 Orchestration - Airflow/Astronomer**

## **9.0 Transformation - DBT/Astronomer-Cosmos**

## **10.0 Data Warehouse - BigQuery**

## **11.0 Data Visualization - Looker**

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


DBT profile.yml

aneel_dw:
  outputs:
    dev:
      dataset: data_warehouse
      job_execution_timeout_seconds: 300
      job_retries: 1
      keyfile: <path to your credential>
      location: <location>
      method: service-account
      priority: interactive
      project: <project id>
      threads: 4
      type: bigquery
  target: dev