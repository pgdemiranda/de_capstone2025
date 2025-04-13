{{
    config(
        tags=['componente_tarifarias', 'stg'],
        primary_key='id'
    )
}}

with raw_data as (
    select
        cast(DatGeracaoConjuntoDados as date) as dat_geracao_conjunto_dados,
        cast(DatInicioVigencia as date) as dat_inicio_vigencia,
        cast(DatFimVigencia as date) as dat_fim_vigencia,
        DscResolucaoHomologatoria as dsc_resolucao_homologatoria,
        SigNomeAgente as sig_nome_agente,
        NumCPFCNPJ as num_cpf_cnpj,
        DscBaseTarifaria as dsc_base_tarifaria,
        DscSubGrupoTarifario as dsc_sub_grupo_tarifario,
        DscModalidadeTarifaria as dsc_modalidade_tarifaria,
        DscClasseConsumidor as dsc_classe_consumidor,
        DSCSubclasseConsumidor as dsc_subclasse_consumidor,
        DscDetalheConsumidor as dsc_detalhe_consumidor,
        DscPostoTarifario as dsc_posto_tarifario,
        DscUnidade as dsc_unidade,
        SigNomeAgenteAcessante as sig_nome_agente_acessante,
        DscComponenteTarifario as dsc_componente_tarifario,
        cast(replace(VlrComponenteTarifario, ',', '.') as float64) as vlr_componente_tarifario,
        to_hex(md5(to_json_string(
            struct(
                DatGeracaoConjuntoDados, DatInicioVigencia, DatFimVigencia,
                DscResolucaoHomologatoria, SigNomeAgente, NumCPFCNPJ,
                DscBaseTarifaria, DscSubGrupoTarifario, DscModalidadeTarifaria,
                DscClasseConsumidor, DSCSubclasseConsumidor, DscDetalheConsumidor,
                DscPostoTarifario, DscUnidade, SigNomeAgenteAcessante,
                DscComponenteTarifario, VlrComponenteTarifario
            )
        ))) as row_hash
    from {{ source('raw_data', 'componente_tarifarias') }}
),

deduplicated as (
    select 
        * except(row_hash),
        row_hash,
        row_number() over(partition by row_hash order by dat_geracao_conjunto_dados desc) as row_num
    from raw_data
)

select 
    row_number() over(order by row_hash) as id,
    * except(row_num, row_hash)
from deduplicated
where row_num = 1
order by id, dat_inicio_vigencia, dat_fim_vigencia, dsc_resolucao_homologatoria, num_cpf_cnpj