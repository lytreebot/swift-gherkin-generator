# language: pt

@pagamento @financeiro
Funcionalidade: Processamento de pagamentos
  Como operador financeiro
  Eu quero processar pagamentos de forma segura
  Para garantir transações confiáveis

  Contexto:
    Dado que o gateway de pagamento está operacional
    E o sistema antifraude está ativo

  Cenário: Pagamento com cartão de crédito
    Dado um pedido no valor de R$ 150,00
    E um cartão de crédito válido terminando em "4242"
    Quando o cliente confirma o pagamento
    Então a transação é aprovada
    E um comprovante é enviado por email

  Cenário: Pagamento recusado por saldo insuficiente
    Dado um pedido no valor de R$ 500,00
    E um cartão com saldo insuficiente
    Quando o cliente tenta pagar
    Então a transação é recusada
    E a mensagem "Saldo insuficiente" é exibida
    Mas o pedido permanece ativo

  Esquema do Cenário: Métodos de pagamento aceitos
    Dado um pedido pendente
    Quando o cliente escolhe pagar com "<metodo>"
    Então o pagamento é "<resultado>"

    Exemplos:
      | metodo          | resultado |
      | cartão crédito  | aceito    |
      | cartão débito   | aceito    |
      | boleto          | aceito    |
      | criptomoeda     | recusado  |
