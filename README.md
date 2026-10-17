# PerDay

Journal para iPhone, iPad e Mac Catalyst, feito em SwiftUI e SwiftData.

## Verificar o projeto

Requisitos: macOS 27 e Xcode 27 em `/Applications/Xcode.app`. É possível selecionar outra instalação pela variável `DEVELOPER_DIR`.

```sh
bash Scripts/verify.sh
```

Esse comando verifica a formatação com `swift-format`, analisa o tamanho dos arquivos, funções, inicializadores e propriedades computadas usando SwiftSyntax, executa os testes do núcleo e compila o aplicativo para iOS Simulator sem assinatura. Não baixa dependências nem exige credenciais. Os arquivos de compilação ficam em `/private/tmp`; use `PERDAY_TEST_BUILD_DIR` e `PERDAY_APP_BUILD_DIR` para escolher outros diretórios.

Comandos individuais:

```sh
bash Scripts/test.sh
bash Scripts/build.sh
bash Scripts/check-style.sh
```

Para formatar alterações:

```sh
xcrun swift-format format --in-place --recursive PerDay Tests Package.swift
```

## Organização

- `PerDay/Features/Blocks/Models`: blocos, componentes, rascunhos e histórico das tarefas.
- `PerDay/Features/Blocks/Services`: contrato de persistência, adaptador SwiftData e revisão de ocorrências.
- `PerDay/Features/Home/Models`: estado do diário, transações, exclusão e desfazer.
- `PerDay/Features/Home/Views`: composição da tela, navegação, linha do tempo e controles.
- `PerDay/Features/Voice/Models`: resultado tipado da captura e detecção de atividade sonora.
- `PerDay/Features/Voice/Services`: geração com Apple Intelligence, validação de evidências e composição de rascunhos.
- `Tests/PerDayCoreTests`: testes determinísticos com repositório e gerador de voz falsos nomeados.

## Decisões preservadas

`NoteBlockModel` mantém o nome e os campos persistidos para preservar a compatibilidade com os dados existentes. A leitura de componentes antigos continua adaptando dados em memória, com identidades estáveis. Não há migração destrutiva de armazenamento.

Editar uma ocorrência cria uma exceção independente. Editar esta e as futuras ocorrências divide a série, preserva o passado e substitui os segmentos posteriores na mesma transação. Uma falha de persistência aciona rollback; rascunhos e oportunidades de desfazer continuam disponíveis.

O controlador recebe o repositório, calendário, data inicial e feedback pelo construtor. O interpretador recebe o gerador, calendário e relógio. Datas de calendário não são calculadas somando segundos. As extrações de IA precisam de evidência no texto original para criar componentes.

## Alcance das verificações

Os testes cobrem o núcleo de dados, rascunhos, recorrência, salvamento, exclusão/desfazer, evidências de captura, interpretação com um gerador falso, silêncio e decisões de navegação. Helpers privados são exercitados por esses comportamentos. A compilação verifica a integração das telas e dos adaptadores Apple.

A auditoria de tamanho impõe arquivos com menos de 500 linhas e corpos de funções, inicializadores e acessores com até 20 linhas após formatação. Declarações e assinaturas quebradas pelo formatador são contabilizadas separadamente do corpo. Delegações triviais permanecem curtas, sem linhas artificiais para atingir um mínimo.

Não há cobertura automatizada de todos os helpers visuais nem dos frameworks reais de microfone, download de idiomas e Apple Intelligence. Permissões, interrupções de áudio, acessibilidade, gestos e aparência precisam de uma validação em aparelho. Nenhuma porcentagem de cobertura ou certificação de “100% clean code” é presumida.

O aplicativo não adiciona logs de depuração com conteúdo do diário ou transcrições. Caso observabilidade seja introduzida, use eventos JSON estruturados sem conteúdo pessoal; os scripts apresentam texto destinado à pessoa que os executa.
