---
layout: default
title: "O escritor de PDF headless"
description: "A pilha Cairo e FreeType, o mapeamento de fontes e a exportação de PDF determinística."
lang: pt-BR
---

# O escritor de PDF headless — o corpo Cairo + FreeType

Esta página registra o escritor de PDF headless: a pilha Cairo e FreeType, a política de mapeamento de fontes, o modo determinístico e o teste de aceitação contra o oráculo json-report.

*Escrito na data original; fatos do estado atual reconciliados em 2026-11-22.*

**Status (2026-11-20): implementado, no Linux e no Windows, e verde.** `mad export
--format pdf` e o `export` do `mad serve` gravam um PDF em ambas as engines headless;
o corpo Apple de `MADReportExporterPDF` não mudou e ainda grava a mesma
amostra London de 43.177 bytes, 5 páginas, `sha256 3eb2f1c4…` sob `--deterministic`.
As seções abaixo são o registro entregue; o histórico de decisões que levou até aqui
(status, pilhas candidatas, questões em aberto) está no final.

## O que é

A lacuna que isto fecha sempre foi apenas a escrita. `MADReportPageBuilder` prepara o
documento e percorre as páginas; `html`, `html-flow` e `json-report` já leem
essa caminhada e são idênticos em bytes entre plataformas. O escritor de PDF pega as mesmas
páginas percorridas e as desenha:

* `MADReportExporterPDFCairo` (`MAD/Source/MADReportExporterPDFCairo.m`) é o
  corpo não Apple de `MADReportExporterPDF`. Na Apple o exportador mantém seu caminho Core
  Graphics; fora da Apple o mesmo `exportDocument:toURL:options:error:` entrega o
  documento aqui.
* O escritor prepara o documento exatamente como o corpo Apple
  (`+MADReportPageBuilder prepareDocumentForRender:`), cria uma superfície PDF Cairo
  nos limites da página e, para cada página percorrida, desenha a tela branca, o texto
  de cada linha em seu quadro, cada imagem e as decorações de texto.
* `+isAvailable` responde YES em todas as plataformas e `+unavailableReason` é nil.
  Um pacote de fontes ausente é um erro de exportação com sua própria mensagem, não um
  substituto silencioso.

## A pilha e suas licenças

| Componente | Versão | Licença | Papel |
|---|---|---|---|
| cairo | 1.18.6 (tag git, commit fixado) | **MPL-1.1** (a opção MPL) | a superfície PDF e o desenho |
| pixman | 0.46.4 (tag git, commit fixado) | MIT | o núcleo de rasterização do cairo |
| FreeType | 2.15.0 | **FTL** | avanços, kerning e contornos de glifos |
| Liberation Sans/Serif/Mono | 2.1.5 | **SIL OFL 1.1** | as faces substitutas |

Sem Pango: a caminhada já resolve o quadro, o texto, a fonte, o tamanho, os traços
e o alinhamento de cada linha, e a largura do quadro é o único limite de quebra de linha
(`NSLineBreakByTruncatingTail`). O que resta são avanços e kerning, que o
FreeType fornece diretamente. O cairo é compilado apenas com a superfície PDF — FreeType
e zlib dentro; fontconfig, Pango/glib, Xlib/XCB, Quartz e os backends de imagem
diferentes de PNG fora — então ele não puxa nada além da tabela acima (zlib e
libpng já estavam lá para a pilha de códigos de barras).

Os textos estão em `ThirdParty/Licenses/` (`cairo-MPL-1.1.txt`,
`pixman-MIT.txt`, `freetype-FTL.txt`, `liberation-OFL-1.1.txt`) e o registro
é `THIRD_PARTY_LICENSES.md` §3.5, §9 (imagem Linux) e §10 (engine Windows).
Nenhum dos quatro adiciona obrigação de relink, então a oferta escrita em
`ThirdParty/Licenses/README.md` não muda. A janela Sobre do Windows lista
todos os quatro a partir de `WindowsLicenseRegistry`.

## O mapeamento de fontes

Os documentos nomeiam fontes Apple; o pacote carrega Liberation, então um nome é mapeado para
uma família e depois para uma face pelos sinalizadores de negrito e itálico do elemento (e por qualquer
peso ou inclinação que o próprio nome declare, por exemplo `HelveticaNeue-Bold`):

| Fonte do documento | Substituta | Notas |
|---|---|---|
| Helvetica Neue, Helvetica, Arial, Verdana, Tahoma, Trebuchet MS, Calibri, system | Liberation Sans | Gêmea métrica da Arial, então as linhas Helvetica/Arial ficam próximas; **Verdana é mais larga que Liberation Sans**, então uma linha Verdana é mais estreita que a do Core Graphics e pode truncar antes |
| Courier, Courier New, Menlo, Consolas | Liberation Mono | Gêmea métrica da Courier New |
| Times New Roman, Times, Georgia, Palatino, Baskerville, Garamond | Liberation Serif | Gêmea métrica da Times New Roman; **Georgia é mais larga que Liberation Serif** |
| qualquer outra | Liberation Sans | o próprio recurso alternativo do renderizador é a fonte do sistema, que a engine headless não tem |

Peso e inclinação escolhem a face (`Regular`, `Bold`, `Italic`, `BoldItalic`);
sublinhado e tachado são desenhados como retângulos preenchidos sob/através do
trecho medido, usando as métricas de sublinhado PostScript da face. O alinhamento é o do
estilo (`left`, `center`, `right`; justificado e natural desenham à esquerda, correspondendo ao
fac-símile HTML). Um trecho mais largo que seu quadro é cortado e termina com `…`, a
regra de cauda truncada do renderizador.

**O residual são as métricas das substitutas.** A página, o quadro de cada linha, o
texto resolvido de cada linha, seu mapeamento de família de fonte, tamanho, peso, inclinação e alinhamento
são os da caminhada e são exatos. A largura de uma linha dentro de seu quadro é a
da face substituta, então uma linha é desenhada um pouco mais larga ou mais estreita que a do Mac —
mais visivelmente para Verdana e Georgia, cujas faces reais não são métricamente compatíveis
com nada no pacote. Esta é uma diferença visual, não estrutural;
o teste de oráculo compara texto e quadros, não extensões de glifos.

## Determinismo

`MADReportExportOptionsDeterministic` fixa as duas datas que o Cairo de outra forma
tomaria do relógio (`CAIRO_PDF_METADATA_CREATE_DATE` / `_MOD_DATE`) no mesmo
instante que o corpo Apple fixa em seu trailer, `2001-01-12T00:00:00Z` (a época
do PDF). O Cairo não grava `/ID` de trailer, e sua numeração de objetos, tags de subconjunto
de fontes, compressão e árvores de páginas são determinísticas, então duas exportações de um
relatório inalterado são os mesmos bytes. O teste prova isso.

Um perigo do lado do escritor teve de ser removido para manter isso verdadeiro: o cairo armazena em cache suas
faces de fonte e fontes escaladas pelo ponteiro `FT_Face`, então um escritor que abrisse
e liberasse um conjunto de faces por exportação poderia receber uma entrada de cache obsoleta quando
o alocador reutilizasse um endereço, e o fluxo de conteúdo às vezes mudaria
de `Tj` para deslocamentos `TJ` por glifo. As faces agora são estáticas carregadas uma vez por processo,
e as exportações são serializadas sob um bloqueio recursivo enquanto são
compartilhadas.

Entre plataformas, os dois escritores não precisam concordar byte a byte, mas a saída Cairo do
fixture London tem o mesmo tamanho no Linux e no Windows e difere em 44
bytes apenas — os prefixos de subconjunto de fontes que o cairo gera (ele faz hash dos glifos como
`unsigned long`, 8 bytes no Linux e 4 no Windows).  O texto, a geometria e a estrutura
de páginas são idênticos.

A superfície é restrita ao **PDF 1.4**: uma tabela de referência cruzada clássica e
objetos simples. O padrão 1.7 do Cairo grava fluxos de objetos e de referência cruzada,
o que não é mais fácil de desenhar e é mais difícil de ler de volta; a 1.4 também é a base
de leitores mais ampla. Uma consequência: a API PDF do Cairo não tem TrimBox, então o
MediaBox da página é US Letter e o conteúdo é desenhado dentro do mesmo corte de 1pt que a caminhada
usa (`[1, 1, 610, 790]`); o corte é estrutural nos quadros, não uma caixa PDF.

## O desenho

Para cada página, no espaço de usuário PDF do cairo (origem no canto superior esquerdo, y para baixo; o cairo
grava a inversão `1 0 0 -1 0 H cm` sozinho, então os quadros da caminhada passam
inalterados):

* a caixa de corte branca, como faz o `drawWhiteCanvas:pageRect:` do renderizador Apple;
* cada linha de texto: a face e o tamanho de `MADReportLineStyle`, o texto resolvido
  da linha, os glifos posicionados com os avanços e o kerning do FreeType no
  tamanho da linha (`FT_KERNING_UNFITTED`, então a formação depende apenas da face e do
  tamanho), na borda esquerda (ou centralizada/direita) do quadro e em sua linha de base;
* cada imagem: o PNG armazenado de um elemento de imagem ou o símbolo de um código de barras
  (`MADReportLineRepresentation -imageData`, renderizado sob demanda), ajustado por proporção ao
  quadro como o fac-símile HTML o ajusta (`object-fit: contain`), decodificado
  pelo leitor PNG do cairo;
* as decorações: sublinhado e tachado como retângulos preenchidos;
* `cairo_show_page` (e o preenchimento branco) por página.

A caminhada de páginas é uma transação de leitura por página, como em todo o resto; as imagens são
lidas depois que ela fecha e não custam nada para um documento sem elas.

## O teste de aceitação

`Linux/Tests/MADPDFExportTests.m` (e `Windows/Engine/Tests/`) abre o fixture London,
adiciona um código de barras e uma imagem, atualiza e exporta. Ele lê o PDF
de volta com um pequeno leitor PDF 1.4 no teste (árvore de páginas, MediaBox, fluxos de conteúdo,
mapas ToUnicode de fontes) e o compara com o `json-report` para o mesmo
documento — o oráculo com o qual ambas as plataformas concordam byte a byte:

* a contagem de páginas e o MediaBox US Letter de cada página;
* o quadro de cada linha percorrida dentro do corte de 1pt;
* o texto de cada linha de texto, na ordem da caminhada, página por página (com a
  reticência de cauda truncada permitida onde o quadro é mais estreito que o texto);
* o código de barras e a imagem como XObjects de imagem, não texto;
* duas exportações determinísticas idênticas em bytes, com a data fixada; uma exportação
  comum tomando a data do relógio.

`MADReportExporterTests` também exporta o fixture London simples e verifica cinco
páginas, a contagem de páginas da caminhada. O pin de bytes da Apple não é um teste headless: a
suíte Apple ainda verifica a exportação de 43.177 bytes / `3eb2f1c4…`, e o
corpo `#if __APPLE__` não foi tocado.

## Compilá-lo

* **Linux** — `Linux/libraries.conf` fixa pixman, FreeType, cairo e o
  tarball Liberation; `Linux/lib/libraries.sh` tem `build_pixman` (meson),
  `build_freetype` (autoconf, somente núcleo), `build_cairo` (meson, a superfície PDF)
  e `build_liberation` (as doze faces em
  `${PREFIX}/share/mad/fonts`). A imagem os instala em `/usr/local`; o
  estágio de runtime copia `/usr/local/share/mad` para as fontes. O
  `toolchain-base` do Dockerfile precisa de `meson` e `ninja-build` (o sistema de compilação do cairo e do pixman)
  e `xz-utils` (o pin do FreeType é `.tar.xz`).
* **Windows** — `Windows/Engine/build.ps1` compila o FreeType com seu CMake, pixman
  e cairo com Meson sob o ambiente MSVC (cairo com seu backend DWrite,
  que a fonte win32 do cairo exige para vincular) (a cunha pkg-config que a
  compilação do libpq já precisava encontra os pins locais através de arquivos `.pc` gerados),
  vincula os três `.lib` estáticos em `mad.exe` e copia as
  faces Liberation para `Build\fonts`. O escritor procura
  `<exe>/fonts`, `<exe>/../fonts`, `<exe>/../share/mad/fonts`,
  `/usr/local/share/mad/fonts`, `/usr/share/mad/fonts`,
  `/usr/local/share/fonts/liberation`, `/usr/share/fonts/truetype/liberation`
  e uma substituição `MAD_FONTS_DIR`.

As fontes são arquivos de dados, não código: um pacote Windows deve distribuir
`Windows/Engine/build/fonts` ao lado de `mad.exe`, e a imagem Linux já
as carrega em `/usr/local/share/mad/fonts`.

## O corpo Apple não mudou

O caminho `#if __APPLE__` de `MADReportExporterPDF` — Core Graphics,
`MADPrintPageRenderer`, a fixação de metadados — está intocado. O alvo Apple
não vincula Cairo, e o código-fonte do novo escritor não está em seu alvo Xcode. Os
comandos de compilação Apple para o registro:

	xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
		-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
		-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci

(Eles não são executados na estação de trabalho Windows — não há Xcode lá; os
arquivos Apple que este incremento toca são os braços não Apple do exportador e seus
comentários.)

## Limites deliberados

* **Paridade estrutural, não de bytes** — o escritor do Core Graphics não pode ser reproduzido.
  O oráculo é a caminhada (`json-report`/`html`), não o PDF Apple.
* **Sem TrimBox** — a API PDF do cairo não tem nenhum; o conteúdo está dentro do corte.
* **Texto latino, da esquerda para a direita** — o posicionamento de glifos é avanços do FreeType + a
  tabela `kern`, não uma engine de formação (sem HarfBuzz/Pango): sem ligaduras, sem
  composição de marcas combinantes, sem reordenação bidirecional. Os campos e rótulos
  dos documentos são latinos; um documento que não fosse desenharia o próprio
  glifo de cada ponto de código na ordem lógica.
* **Métricas substitutas** — veja o residual acima (Verdana e Georgia as
  maiores lacunas).
* **O seletor de formato do WPF Viewer do Windows** não lista PDF; `mad export
  --format pdf` e o `export` do `mad serve` listam, que é a superfície do fechamento.
  Adicionar a linha do seletor é uma mudança de interface com seus próprios recursos de string.

---

## O registro de decisão anterior

Estas seções são mantidas para o histórico de decisões, não como instruções.

### As pilhas candidatas (MAD_LINUX.md §10.2)

| opção | licença | o que oferece | o que custa |
|---|---|---|---|
| **Cairo + Pango** (+ FreeType/HarfBuzz) | LGPL-2.1/MPL-1.1, LGPL-2.1, FTL/GPLv2-dual, MIT | desenho vetorial com uma superfície PDF e layout de texto real | uma nova dependência na imagem e seu trabalho de licença/aviso |
| **libharu** | zlib | saída PDF, permissiva | apenas PDF, sem engine de layout |
| **Skia** | BSD-3 | capacidade mais próxima de CG + Core Text | uma compilação C++ pesada |
| **emissor de PDF escrito à mão** | nenhuma | nenhuma dependência | tipografia aproximada, um segundo caminho de desenho |

**O que foi escolhido (2026-11-20): Cairo + FreeType, sem Pango.** A caminhada fornece
o layout; restam apenas avanços e kerning de glifos, e a tabela `kern` do FreeType
os fornece sem uma engine de layout. O Pango teria adicionado uma dependência (e
sua árvore LGPL/glib) para quebra de linha que ninguém precisa.

### As questões em aberto, respondidas

1. **Fontes** — veja a tabela de mapeamento acima: Liberation Sans/Serif/Mono, escolhidas
   pelas famílias métricamente compatíveis, com os residuais de Verdana e Georgia
   registrados.
2. **Qual pilha e licença** — Cairo (MPL-1.1), pixman (MIT), FreeType (FTL),
   Liberation (OFL): todas permissivas ou MPL, nenhuma LGPL, sem obrigação de relink.
3. **Onde o escritor vive** — em `MAD`, como `MADReportExporterPDFCairo`, sua própria
   unidade de tradução e cabeçalho oculto, compilado somente fora da Apple. O alvo Apple
   não o vincula.
4. **O PDF de servidor sem supervisão é necessário?** — sim: o verbo `export` da CLI e o
   `export` do `serve` são a superfície, e uma tarefa agendada não tem navegador.
