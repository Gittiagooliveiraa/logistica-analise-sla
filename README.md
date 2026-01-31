# 📦 Análise de SLA Logístico – Case de BI (inspirado no iFood)

Este projeto é um **case educacional de Business Intelligence**, inspirado em desafios reais de operações logísticas de marketplaces como o **iFood**, utilizando **dados públicos em um cenário simulado**.

O objetivo é analisar o **desempenho logístico ponta a ponta**, identificar gargalos operacionais e transformar dados brutos em **insights acionáveis para tomada de decisão**.

---

## 🎯 Objetivos do Projeto
- Avaliar o desempenho das etapas de separação, empacotamento e entrega
- Identificar gargalos logísticos por modal de transporte
- Medir o cumprimento de SLA operacional
- Construir indicadores claros para suporte à decisão

---

## 🗂️ Estrutura dos Dados
Os dados simulam duas fontes operacionais principais:

- **`table_log`**  
  Contém informações de entrega:
  - modal do driver
  - grupo comercial
  - timestamps de criação, coleta e finalização
  - SLA esperado da entrega

- **`table_ops`**  
  Contém dados operacionais da loja:
  - eventos de picking e empacotamento
  - timestamps armazenados em formato JSON

---

## 🛠️ Ferramentas Utilizadas
- **SQL Server**
  - Análise exploratória
  - Criação de views analíticas
  - Cálculo de métricas operacionais

- **Python (Pandas)**
  - Limpeza e validação dos dados
  - Cálculo de KPIs
  - Análises estatísticas e exploratórias

- **Power BI**
  - Construção de dashboards
  - Visualização de KPIs
  - Storytelling analítico

---

## 📊 KPIs Desenvolvidos
- Tempo médio de separação
- Tempo médio de empacotamento
- Tempo médio de espera do driver
- Tempo total de entrega
- % de pedidos dentro do SLA (SLA geral)
- Gargalo logístico dominante por modal

---

## 📈 Dashboard
O dashboard final permite:

- Comparar performance por modal de entrega
- Avaliar o SLA geral da operação
- Identificar visualmente gargalos logísticos
- Analisar diferenças de performance por grupo comercial

### 🔎 Insight principal
> **O baixo SLA geral está fortemente associado ao tempo de separação, especialmente nos modais BIKE e CAR, indicando uma oportunidade clara de ganho operacional na etapa inicial do processo.**

---

## 📁 Estrutura do Repositório
```text
📦 logistica-analise-sla
 ┣ 📂 sql
 ┃ ┗ views_logistica.sql
 ┣ 📂 python
 ┃ ┗ analise_kpis.ipynb
 ┣ 📂 powerbi
 ┃ ┗ dashboard_logistica.pbix
 ┗ README.md
