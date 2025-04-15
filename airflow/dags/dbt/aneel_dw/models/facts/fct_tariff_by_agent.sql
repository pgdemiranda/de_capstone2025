{{
    config(
        tags=['tariff', 'agents', 'fact'],
        unique_key='tariff_fact_id'
    )
}}

with fact_tariff as (
    select
        {{ dbt_utils.generate_surrogate_key([
            'a.id',
            't.id',
            't.dat_inicio_vigencia'
        ]) }} as tariff_fact_id,
        t.dat_inicio_vigencia,
        t.dat_fim_vigencia,
        a.sig_nome_agente,
        a.sig_nome_agente_acessante,
        a.num_cpf_cnpj,
        t.dsc_resolucao_homologatoria,
        t.dsc_componente_tarifario,
        t.vlr_componente_tarifario as tariff_value
    from {{ ref('dim_tariff') }} t
    inner join {{ ref('dim_agents') }} a 
        on t.id = a.id
        and t.num_cpf_cnpj = a.num_cpf_cnpj
        and t.sig_nome_agente_acessante = a.sig_nome_agente_acessante
)

select * from fact_tariff