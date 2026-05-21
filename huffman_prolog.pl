/*
    EP2 - Codificacao de Huffman em Prolog

Integrantes:

Fabyani Tiva Yan - RA: 10431835
Rafael Araujo Cabral Moreira - RA 10441919

Link do repositório no Github usado para desenvolvimento:
https://github.com/FabyaniYan/Paradigmas-Projeto2
*/

:- use_module(library(readutil)).
:- initialization(main, main).

% codificar_arquivo(+Entrada, +Saida)
% Le o arquivo Entrada, aplica a codificacao de Huffman
% e grava apenas a sequencia de bits no arquivo Saida.
codificar_arquivo(Entrada, Saida) :-
    read_file_to_string(Entrada, Texto, []),
    codificar_texto(Texto, Bits, _Tabela),
    setup_call_cleanup(
        open(Saida, write, Stream),
        escrever_bits(Stream, Bits),
        close(Stream)
    ).

% codificar_texto(+Texto, -Bits, -Tabela)
% Transforma o texto original em uma lista de bits,
% usando uma tabela de Huffman criada a partir do proprio texto.
codificar_texto(Texto, Bits, Tabela) :-
    string_chars(Texto, Caracteres),
    limpar_texto(Caracteres, Limpos),
    codificar_limpos(Limpos, Bits, Tabela).

% Caso o arquivo nao tenha caracteres validos.
codificar_limpos([], [], []) :-
    !.
codificar_limpos(Limpos, Bits, Tabela) :-
    tabela_frequencias(Limpos, Frequencias),
    arvore_huffman(Frequencias, Arvore),
    tabela_codigos(Arvore, Tabela),
    codificar_caracteres(Limpos, Tabela, Bits).

% decodificar_bits(+Bits, +Tabela, -Texto)
% Predicado auxiliar para testes: decodifica uma lista de bits
% usando a tabela gerada anteriormente.
decodificar_bits(Bits, Tabela, Texto) :-
    decodificar_bits(Bits, Tabela, [], Caracteres),
    string_chars(Texto, Caracteres).

% limpar_texto(+Caracteres, -Limpos)
% Mantem apenas letras e numeros, convertendo letras para minusculas.
limpar_texto([], []).
limpar_texto([C|Cs], [L|Ls]) :-
    char_type(C, alnum),
    !,
    downcase_atom(C, L),
    limpar_texto(Cs, Ls).
limpar_texto([_|Cs], Ls) :-
    limpar_texto(Cs, Ls).

% tabela_frequencias(+Caracteres, -Frequencias)
% Ordena os caracteres e conta quantas vezes cada um aparece.
tabela_frequencias(Caracteres, Frequencias) :-
    msort(Caracteres, Ordenados),
    contar_ordenados(Ordenados, Frequencias).

contar_ordenados([], []).
contar_ordenados([C|Cs], [C-N|Resto]) :-
    contar_iguais(Cs, C, 1, N, Outros),
    contar_ordenados(Outros, Resto).

contar_iguais([C|Cs], C, Acc, N, Resto) :-
    !,
    Acc1 is Acc + 1,
    contar_iguais(Cs, C, Acc1, N, Resto).
contar_iguais(Resto, _, N, N, Resto).

% arvore_huffman(+Frequencias, -Arvore)
% Cria a arvore de Huffman a partir da tabela de frequencias.
arvore_huffman(Frequencias, Arvore) :-
    folhas_ordenadas(Frequencias, Folhas),
    montar_arvore(Folhas, item(_, _, Arvore)).

% Cada item guarda: frequencia, chave de desempate e arvore.
folhas_ordenadas(Frequencias, Folhas) :-
    findall(
        item(Freq, Simbolo, folha(Simbolo, Freq)),
        member(Simbolo-Freq, Frequencias),
        Itens
    ),
    sort(Itens, Folhas).

% Quando resta apenas uma arvore, ela e a arvore final.
montar_arvore([Arvore], Arvore).
montar_arvore([item(F1, K1, A1), item(F2, K2, A2)|Resto], Arvore) :-
    F is F1 + F2,
    menor_chave(K1, K2, Chave),
    inserir_ordenado(item(F, Chave, no(F, A1, A2)), Resto, NovasArvores),
    montar_arvore(NovasArvores, Arvore).

% Usado apenas para desempate, deixando o resultado mais deterministico.
menor_chave(A, B, A) :-
    A @=< B,
    !.
menor_chave(_, B, B).

% Insere uma nova arvore mantendo a lista ordenada.
inserir_ordenado(Item, [], [Item]).
inserir_ordenado(Item, [Atual|Resto], [Item, Atual|Resto]) :-
    Item @=< Atual,
    !.
inserir_ordenado(Item, [Atual|Resto], [Atual|Novos]) :-
    inserir_ordenado(Item, Resto, Novos).

% tabela_codigos(+Arvore, -Tabela)
% Gera a tabela Simbolo-Codigo a partir da arvore de Huffman.
% Caso exista apenas um simbolo, ele recebe o codigo [0].
tabela_codigos(folha(Simbolo, _), [Simbolo-[0]]) :-
    !.
tabela_codigos(Arvore, Tabela) :-
    codigos_da_arvore(Arvore, [], TabelaInvertida),
    sort(TabelaInvertida, Tabela).

codigos_da_arvore(folha(Simbolo, _), Prefixo, [Simbolo-Codigo]) :-
    reverse(Prefixo, Codigo).
codigos_da_arvore(no(_, Esquerda, Direita), Prefixo, Tabela) :-
    codigos_da_arvore(Esquerda, [0|Prefixo], TabelaEsquerda),
    codigos_da_arvore(Direita, [1|Prefixo], TabelaDireita),
    append(TabelaEsquerda, TabelaDireita, Tabela).

% codificar_caracteres(+Caracteres, +Tabela, -Bits)
% Substitui cada caractere pelo seu codigo na tabela.
codificar_caracteres(Caracteres, Tabela, Bits) :-
    codificar_caracteres(Caracteres, Tabela, Bits, []).

codificar_caracteres([], _, Bits, Bits).
codificar_caracteres([C|Cs], Tabela, Bits, Final) :-
    memberchk(C-Codigo, Tabela),
    anexar_codigo(Codigo, Bits, Resto),
    codificar_caracteres(Cs, Tabela, Resto, Final).

% Anexa o codigo usando lista diferencial.
anexar_codigo([], Bits, Bits).
anexar_codigo([B|Bs], [B|Resto], Final) :-
    anexar_codigo(Bs, Resto, Final).

% Predicados auxiliares de decodificacao, usados apenas para teste.
decodificar_bits([], _, Acc, Texto) :-
    reverse(Acc, Texto).
decodificar_bits(Bits, Tabela, Acc, Texto) :-
    member(Simbolo-Codigo, Tabela),
    prefixo(Codigo, Bits, Resto),
    !,
    decodificar_bits(Resto, Tabela, [Simbolo|Acc], Texto).

prefixo([], Bits, Bits).
prefixo([B|Bs], [B|Resto], Final) :-
    prefixo(Bs, Resto, Final).

% escrever_bits(+Stream, +Bits)
% Grava a lista de bits no arquivo sem espacos.
escrever_bits(_, []).
escrever_bits(Stream, [B|Bs]) :-
    write(Stream, B),
    escrever_bits(Stream, Bs).

% Execucao padrao exigida pelo enunciado:
% swipl -q -s huffman_fabyani.pl
% le o arquivo "in" e cria o arquivo "out".
main([]) :-
    !,
    codificar_arquivo('in', 'out'),
    writeln('Arquivo out gerado com sucesso.').

% Tambem permite passar nomes pela linha de comando:
% swipl -q -s huffman_fabyani.pl -- entrada.txt saida.txt
main([Entrada, Saida]) :-
    !,
    codificar_arquivo(Entrada, Saida),
    format('Arquivo ~w gerado com sucesso.~n', [Saida]).

main(_) :-
    writeln('Uso padrao: swipl -q -s huffman_fabyani.pl'),
    writeln('Ou: swipl -q -s huffman_fabyani.pl -- arquivo_entrada arquivo_saida'),
    halt(1).
