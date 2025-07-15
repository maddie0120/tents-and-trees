%110206 Madalena Yang
:- use_module(library(clpfd)). % para poder usar transpose/2
:- set_prolog_flag(answer_write_options,[max_depth(0)]). % ver listas completas
:- ['puzzlesAcampar.pl']. % Ficheiro dado. No Mooshak tera mais puzzles


% ******************************************* %
%                4.1 CONSULTAS                %
% ******************************************* %
%==================== vizinhanca/2 ====================
/* 
Este predicado eh verdade se Vizinhanca eh uma lista ordenada de cima
para baixo e da esquerda para a direita, sem elementos repetidos,
com as coordenadas das posicoes imediatamente acima, a esquerda,
a direita e abaixo da coordenada (L, C)
*/

vizinhanca((L, C), Vizinhanca) :-
    L_1 is L - 1, % linha anterior
    C_1 is C - 1, % coluna anterior
    C1 is C + 1, % coluna seguinte
    L1 is L + 1, % linha seguinte
    Vizinhanca = [(L_1, C), (L, C_1), (L, C1), (L1, C)].


%==================== vizinhancaAlargada/2 ====================
/*
Este predicado e verdade se VizinhancaAlargada eh uma lista ordenada de
cima para baixo e da esquerda para a direita, sem elementos repetidos,
com as coordenadas anteriores e ainda as diagonais da coordenada (L, C)
*/

vizinhancaAlargada((L, C), VizinhancaAlargada) :- 
    L_1 is L - 1, %linha anterior
    C_1 is C - 1, %colunha anterior
    L1 is L + 1, %linha seguinte
    C1 is C + 1, %coluna seguinte
    VizinhancaAlargada = [(L_1, C_1), (L_1, C), (L_1, C1), (L, C_1), 
                        (L, C1), (L1, C_1), (L1, C), (L1, C1)].


%==================== todasCelulas/2 ====================
/*
Este predicado eh verdade se TodasCelulas eh uma lista ordenada de cima
para baixo e da esquerda para a direita, sem elementos repetidos, com
todas as coordenadas do tabuleiro Tabuleiro
*/

todasCelulas(T, TodasCelulas) :-
    findall((L, C),
        (
            nth1(L, T, Linha), 
            nth1(C, Linha, _)
        ), 
        TodasCelulas
    ).


%==================== todasCelulas/3 ====================
/*
Este predicado eh verdade se TodasCelulas eh uma lista ordenada de cima
para baixo e da esquerda para a direita, sem elementos repetidos, com
todas as coordenadas do tabuleiro T em que existe um objeto do tipo Obj
*/

todasCelulas(T, TodasCelulas, Obj) :-
    findall((L, C), 
        (
            nth1(L, T, Linha), 
            nth1(C, Linha, Celula),
            (
                (var(Obj), var(Celula)); 
                Celula == Obj
            )
        ), 
        TodasCelulas
    ).


%==================== calculaObjectosTabuleiro/4 ====================
/*
Este predicado eh verdade se T for um tabuleiro, Objeto for o tipo de
objeto que se procura, e CLinhas e CColunas forem, respetivamente,
listas com o numero desses objetos por linha e por coluna
*/

calculaObjectosTabuleiro(T, CLinhas, CColunas, Objeto) :-
    maplist(contaObjetoPorLinha(Objeto), T, CLinhas),
    transpose(T, TTransposto),
    maplist(contaObjetoPorLinha(Objeto), TTransposto, CColunas).

%--------------- contaObjetoPorLinha/3 ---------------
/*
Eh um predicado auxiliar para contar o numero de objetos por linha
Este predicado eh dividido em dois casos: 
    - Caso em que o Objeto e 'a' (arvore), 't' (tenda) ou 'r' (relva)
    - Caso em que Objeto e uma variavel
*/

contaObjetoPorLinha(Objeto, Linha, Contador) :-
    nonvar(Objeto),
    include(==(Objeto), Linha, TodosObjetos),
    length(TodosObjetos, Contador).

contaObjetoPorLinha(Objeto, Linha, Contador) :-
    var(Objeto),
    findall(Var, 
        (
            member(Var, Linha), 
            var(Var)
        ), 
        TodosObjetos
    ), 
    length(TodosObjetos, Contador).


%==================== celulaVazia/2 ====================
/*
Este predicado eh verdade se T for um tabuleiro que nao tem nada ou
tem relva nas coordenadas (L, C). Caso as coordenadas (L, C) nao
fizerem parte do tabuleiro, o predicado devolve o T
*/

celulaVazia(T, (L, C)) :-
    nth1(L, T, Linha), 
    nth1(C, Linha, Celula),
    (
        Celula == 'r';
        var(Celula)
    ).


% ******************************************* %
%       4.2 INSERCAO DE TENDAS E RELVA        %
% ******************************************* %
%==================== insereObjectoCelula/3 ====================
/*
Este predicado eh verdade se T eh um tabuleiro e (L, C) forem as
coordenadas onde queremos inserir o objeto TendaOuRelva
*/

insereObjectoCelula(T, TendaOuRelva, (L, C)) :-
    nth1(L, T, Linha),
    nth1(C, Linha, Celula),
    var(Celula), 
    Celula = TendaOuRelva, 
    !.
insereObjectoCelula(_, _, _).


%==================== insereObjectoEntrePosicoes/4 ====================
/*
Este predicado eh verdade se T eh um tabuleiro, e (L, C1) e (L, C2) sao
as coordenadas, na Linha L, entre as quais (incluindo) se insere o
objeto TendaOuRelva
*/

insereObjectoEntrePosicoes(T, TendaOuRelva, (L, C1), (L, C2)) :-
    findall((L, C), between(C1, C2, C), ListaLC1aLC2),
    maplist(insereObjectoCelula(T, TendaOuRelva), ListaLC1aLC2).


% ******************************************* %
%               4.3 ESTRATEGIAS               %
% ******************************************* %

% Predicados auxiliares que extraem algo (seletores)
obtemTabuleiro(Puzzle, T) :- 
    Puzzle = (T, _, _).
obtemNTendaspor(Puzzle, NTendasporLinha, NTendasporColuna) :- 
    Puzzle = (_, NTendasporLinha, NTendasporColuna).


%==================== relva/1 ====================
/*
Este predicado eh verdade se Puzzle eh um puzzle que, apos a aplicacao
do predicado, tem relva em todas as linhas/colunas cujo numero de
tendas ja atingiu o numero de tendas possivel nessas linhas/colunas
*/

relva(Puzzle) :-
    obtemTabuleiro(Puzzle, T),
    obtemNTendaspor(Puzzle, NTendasporLinha, NTendasporColuna),

    aplicaRelva(T, NTendasporLinha),

    transpose(T, TTransposto),
    aplicaRelva(TTransposto, NTendasporColuna).

%--------------- aplicaRelva/2 ---------------
/*
Eh um predicado auxiliar que aplica relva em todas as coordenadas que
sao necessarias, tal como foi referido no predicado anterior
*/

aplicaRelva(T, NTendasporLinha) :- 
    calculaObjectosTabuleiro(T, CLinhas, _, t),
    findall(IndLinha,
        (
            nth1(IndLinha, CLinhas, Num),
            nth1(IndLinha, NTendasporLinha, Num)
        ),
        IndiceLinhas
    ),
    todasCelulas(T, TodasCelulas),
    findall((L, C),
        (
            member(L, IndiceLinhas), 
            member((L, C), TodasCelulas)
        ),
        Coordenadas
    ), 
    maplist(insereObjectoCelula(T, r), Coordenadas).


%==================== inacessiveis/1 ====================
/*
Este predicado eh verdade se T eh um tabuleiro que, apos a aplicacao
do predicado, tem relva em todas as posicoes inacessiveis, ou seja,
posicoes que nao estao na vizinhanca de nenhuma arvore
*/

inacessiveis(T) :-
    todasCelulas(T, Arvores, a),
    maplist(vizinhanca, Arvores, VizArvore),
    flatten(VizArvore, VizArvNumaLista),
    todasCelulas(T, TodasCelulas), 
    findall(Celula, 
        (
            member(Celula, TodasCelulas), 
            \+ member(Celula, VizArvNumaLista)
        ), 
        PosicoesInacessiveis),
    maplist(insereObjectoCelula(T, r), PosicoesInacessiveis).


%==================== aproveita/1 ====================
/*
Este predicado eh verdade se Puzzle eh um puzzle que, apos a aplicacao
do predicado, tem tendas em todas as linhas e colunas as quais faltavam
colocar X tendas e que tinham exatamente X posicoes livres
*/

aproveita(Puzzle) :- 
    obtemTabuleiro(Puzzle, T),
    obtemNTendaspor(Puzzle, NTendasporLinha, NTendasporColuna),

    calculaObjectosTabuleiro(T, CLinhasTendas, _, t),
    calculaObjectosTabuleiro(T, CLinhasVazios, _, _),
    aplicaAproveita(T, NTendasporLinha, CLinhasTendas, CLinhasVazios),

    calculaObjectosTabuleiro(T, _, CColunasTendas, t),
    calculaObjectosTabuleiro(T, _, CColunasVazios, _),
    transpose(T, TTransposto),
    aplicaAproveita(TTransposto, NTendasporColuna, CColunasTendas, CColunasVazios).

%--------------- aplicaAproveita/2 ---------------
/*
Eh um predicado auxiliar que aplica tenda em todas as coordenadas que
sao necessarias, tal como foi referido no predicado anterior
*/

aplicaAproveita(T, NTendasporLinha, CLinhasTendas, CLinhaVazios) :-
    findall(IndLinha, 
        (
            nth1(IndLinha, NTendasporLinha, NumMaxTendas),
            nth1(IndLinha, CLinhasTendas, NumTendas),
            nth1(IndLinha, CLinhaVazios, NumVazios),
            NumVazios is NumMaxTendas - NumTendas,
            NumVazios \= 0
        ),
        Indices),

    todasCelulas(T, TodasCelulas),
    findall((L, C),
        (
            member(L, Indices), 
            member((L, C), TodasCelulas)
        ),
        Coordenadas
    ), 
    maplist(insereObjectoCelula(T, t), Coordenadas).


%==================== limpaVizinhancas/1 ====================
/*
Este predicado eh verdade se Puzzle eh um puzzle que, apos a aplicacao
do predicado, tem relva em todas as posicoes a volta de uma tenda, ou
seja, na vizinhanca alargada de uma tenda, de modo a garantir que mais
nenhuma tenda sera ai colocada
*/

limpaVizinhancas(Puzzle) :-
    obtemTabuleiro(Puzzle, T),
    todasCelulas(T, Tendas, t),
    maplist(vizinhancaAlargada, Tendas, VizAlarTendas),
    flatten(VizAlarTendas, VizAlarTendasNumaLista),
    maplist(insereObjectoCelula(T, r), VizAlarTendasNumaLista).


%==================== unicaHipotese/1 ====================
/*
Este predicado eh verdade se Puzzle eh um puzzle que, apos a aplicacao
do predicado, todas as arvores que tinham apenas uma posicao livre na
sua vizinhanca que lhes permitia ficar ligadas a uma tenda, tem agora
uma tenda nessa posicao
*/

unicaHipotese(Puzzle) :-
    obtemTabuleiro(Puzzle, T),
    todasCelulas(T, Arvores, a),
    todasCelulas(T, Tendas, t), 

    maplist(vizinhanca, Tendas, VizTendas),
    flatten(VizTendas, VizTendasNumaLista),
    
    intersection(VizTendasNumaLista, Arvores, ArvoresComTenda),
    subtract(Arvores, ArvoresComTenda, ArvoresSemTenda), 
    maplist(verificaUnicaPosicao(T), ArvoresSemTenda).

/*
O predicado auxiliar verifica se as arvores sem tenda tem apenas um 
espaco vazio na sua vizinhanca. Em caso positivo, insere uma tenda.
*/
colocaTenda(Tabuleiro, Posicao):-
    vizinhanca(Posicao, Viz),
    findall((L, C), 
            (member((L, C), Viz), (nth1(L, Tabuleiro, Linha), nth1(C, Linha, El)),
            var(El)), [Elemento]),
    insereObjectoCelula(Tabuleiro, t, Elemento).
colocaTenda(_, _).

%--------------- verificaUnicaPosicao/2 ---------------
/*
Eh um predicado auxiliar que verifica se so tem uma unica posicao vazia
na vizinhanca das coordenadas (L, C)
*/

verificaUnicaPosicao(T, (L, C)) :-
    vizinhanca((L, C), VizArv),
    todasCelulas(T, Vazios, _),
    intersection(VizArv, Vazios, VizArvcomVazios),
    (
        % caso so tem uma unica posicao vazia na vizinhanca
        length(VizArvcomVazios, 1),
        maplist(insereObjectoCelula(T, t), VizArvcomVazios)
    ;
        length(VizArvcomVazios, N),
        N \== 1
    ).


% ******************************************* %
%            4.4 TENTATIVA E ERRO             %
% ******************************************* %
%==================== valida/2 ====================
/*
Este predicado eh verdade se LArv (PrimeiraArvore | RestoArvores) e
LTen (LTendas) sao listas com todas as coordenadas em que existem,
respetivamente, arvores e tendas, e eh avaliado para verdade se for
possivel estabelecer uma relacao em que existe uma e uma unica tenda
para cada arvore nas suas vizinhancas
*/

valida([], []).
valida([PrimeiraArvore | RestoArvores], LTendas) :-
    vizinhanca(PrimeiraArvore, Vizinhanca),
    member(Tenda, Vizinhanca),
    select(Tenda, LTendas, RestoTendas),
    valida(RestoArvores, RestoTendas).

%==================== resolve/1 ====================
/*
Este predicado eh verdade se Puzzle eh um puzzle que, apos a aplicacao
do predicado, fica resolvido
*/

% Caso terminal
resolve(Puzzle) :- 
    obtemTabuleiro(Puzzle, T),
    obtemNTendaspor(Puzzle, NTendasporLinha, NTendasporColuna),
    calculaObjectosTabuleiro(T, NTendasporLinha, NTendasporColuna, t), 
    todasCelulas(T, Arvores, a), 
    todasCelulas(T, Tendas, t),
    valida(Arvores, Tendas),
    !.

% Casos recursivos
resolve(Puzzle) :- 
    obtemTabuleiro(Puzzle, T),
    todasCelulas(T, Vazios, _),
    inacessiveis(T),
    aplicaPredicados(Puzzle),
    todasCelulas(T, VaziosApos, _),
    Vazios \== VaziosApos,
    !, 
    resolve(Puzzle).

resolve(Puzzle) :-
    obtemTabuleiro(Puzzle, T),
    todasCelulas(T, Vazios, _),
    member(Celula, Vazios),
    insereObjectoCelula(T, t, Celula),
    limpaVizinhancas(Puzzle),
    resolve(Puzzle), 
    !.

%--------------- aplicaPredicados/1 ---------------
/*
Eh um predicado auxiliar que, tal como o nome diz, aplica os predicados
*/

aplicaPredicados(Puzzle) :-
    relva(Puzzle),
    aproveita(Puzzle),
    relva(Puzzle),
    limpaVizinhancas(Puzzle),
    unicaHipotese(Puzzle),
    limpaVizinhancas(Puzzle).
