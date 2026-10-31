[English](SECURITY.md) | [简体中文](SECURITY_zh.md) | [日本語](SECURITY_ja.md) | **Português (Brasil)**

# Política de Segurança

## Versões suportadas

Apenas a versão mais recente recebe correções de segurança. O projeto ainda não realizou um
release público formal; assim que o fizer, qualquer versão anterior à mais recente deixará de ter
suporte e será recomendado que os usuários atualizem.

| Versão | Suportada |
|---|---|
| release mais recente | :white_check_mark: |
| todas as anteriores | :x: |

## O que está no escopo

* A engine e seus frameworks: o leitor e o gravador de arquivos `.mad`, o
  compilador de consultas, os renderizadores, os drivers (MySQL, SQL Server, PostgreSQL, SQLite) e a
  CLI `mad`.
* O próprio aplicativo, nas partes alcançáveis a partir de um documento ou de uma conexão:
  parsing de documentos, armazenamento de credenciais e qualquer componente que receba uma resposta de
  servidor ou um arquivo como entrada.

Lembre-se do modelo de confiança: um documento `.mad` contém uma consulta, e
abrir um documento significa escolher executar um relatório — o formato é uma definição, não
código em sandbox, e nenhum código executável dentro de um documento é jamais executado.

## Reportando uma vulnerabilidade

**Não abra uma issue pública.** Relate de forma privada:

* Quando o repositório estiver publicado no GitHub: utilize o fluxo **Report a vulnerability**
  do GitHub (**Security → Advisories**), que mantém o relato confidencial e
  nos permite publicar um aviso de segurança (advisory) dando o devido crédito a você quando a correção for lançada.
* Caso contrário, entre em contato diretamente com o mantenedor.

Inclua, se possível: o componente e a versão afetados, um caso mínimo de reprodução
ou o documento/consulta que aciona o problema, e o impacto esperado. Você
receberá uma confirmação de recebimento em até uma semana e uma correção ou avaliação técnica por escrito
assim que estiver disponível.

## Expectativas

Não há programa de recompensa financeira (bug bounty). O projeto é mantido por um único desenvolvedor; o que você
recebe é uma correção rápida, com crédito nominal e um aviso de segurança documentado. Assume-se a divulgação
responsável (o relato permanece privado até que a correção seja disponibilizada), e o aviso
credita os pesquisadores que desejarem ser nomeados.

## Trade-offs conhecidos e aceitos

Estes pontos são decisões de arquitetura, não bugs reportáveis — estão documentados na
especificação e no registro de bugs, e alterá-los é uma decisão de produto:

* O contêiner `.mad` legado (v0) não possui magic bytes (`docs/06-hazards.md`, risco
  H1); a detecção naquele formato é feita pela extensão, enquanto a versão normativa `v1` utiliza magic
  bytes no cabeçalho.
* O cache de renderização é indexado pelo nome do arquivo e pelo tamanho da página, e não pelo conteúdo
  (`docs/05-companion-files.md` §5.3), de modo que editar um documento mantendo o mesmo
  nome pode exibir páginas antigas até que os arquivos de cache sejam removidos.
* As credenciais de banco de dados das suítes de teste em
  [`docs/project/DEVELOPER.md`](docs/project/DEVELOPER.md) são credenciais descartáveis para
  contêineres Docker locais, não segredos de produção.
