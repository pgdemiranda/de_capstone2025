{{
    config(
        tags=['tariff', 'dim'],
        unique_key='id'
    )
}}

with tariff as (
    select distinct
        id,
        dsc_resolucao_homologatoria,
        dsc_componente_tarifario,
        num_cpf_cnpj,
        sig_nome_agente_acessante,
        dat_inicio_vigencia,
        dat_fim_vigencia,
        vlr_componente_tarifario
    from {{ ref('stg_componentes_tarifarias') }}
)

select * 
from tariff
where vlr_componente_tarifario < 0
order by id