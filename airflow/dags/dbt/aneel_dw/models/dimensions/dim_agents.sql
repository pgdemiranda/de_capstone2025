{{
    config(
        tags=['agents', 'dim'],
        unique_key='agent_id'
    )
}}

with agents_distinct as (
    select distinct
        id,
        num_cpf_cnpj,
        sig_nome_agente,
        sig_nome_agente_acessante
    from {{ ref('stg_componentes_tarifarias') }}
),

agents as (
    select 
        {{ dbt_utils.generate_surrogate_key(['num_cpf_cnpj', 'sig_nome_agente', 'sig_nome_agente_acessante']) }} as agent_id,
        id,
        num_cpf_cnpj,
        sig_nome_agente,
        sig_nome_agente_acessante
    from agents_distinct
)

select * from agents