# Half-Life Monitoring (Rainmeter)

Overlay minimalista no estilo de Half-Life para acompanhar o uso de CPU, GPU, RAM, disco e rede diretamente na área de trabalho.

English: [README.md](README.md)

![Prévia do skin](HalfLifeMonitoring.png)

## Recursos
- CPU e GPU em porcentagem com barras horizontais.
- RAM em GB (usado/total) + barra de percentual.
- Disco: leitura e escrita agregadas (KB/s).
- Rede: download e upload (KB/s) em uma única linha.
- Sempre visível no canto superior direito, com fundo translúcido e opção de clique transparente.

## Requisitos
- Windows 10/11 (o UsageMonitor do Rainmeter usa contadores do Windows).
- Rainmeter 4.5+.

## Instalação
Download: https://github.com/kaic/halflife-monitoring/releases

1) **Pacote pronto**: abra `HalfLifeMonitoring_1.0.rmskin` e siga o instalador do Rainmeter.  
2) **Manual**: copie `HalfLifeMonitoring.ini` para `Documentos\\Rainmeter\\Skins\\HalfLifeMonitoring\\` e carregue o skin pelo Rainmeter.

## Como usar
- Ao carregar, o overlay fica no canto superior direito (`WindowX/Y`) com `AlwaysOnTop` ativado e `ClickThrough` ligado para não interferir nos cliques.
- O refresh é a cada 300 ms (`Update=300`).
- Se a GPU ficar em 0%, ajuste `Instance` em `measureGPUUsage` para a instância correta do contador de GPU (via Performance Monitor/UsageMonitor).

## Personalização rápida
- Cores e transparências: `textColor`, `barColor`, `bgColor`.
- Fonte/tamanho: `fontName`, `textSize`.
- Dimensões/padding: `width`, `height`, além de `WindowX`/`WindowY`.
- Comportamento: ligue/desligue `ClickThrough` ou `Draggable` alterando `OnRefreshAction` conforme preferir.

## Estrutura dos arquivos
- `HalfLifeMonitoring.ini` — código-fonte do skin.
- `HalfLifeMonitoring_1.0.rmskin` — pacote instalável.
- `HalfLifeMonitoring.png` — captura de tela.

## Contribuindo
Sugestões, issues e PRs são bem-vindos. Sinta-se à vontade para ajustar contadores, cores e layout, ou para adicionar variantes.

## Licença
MIT — veja `LICENSE`.
