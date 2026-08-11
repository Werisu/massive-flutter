const { initializeApp } = require("firebase-admin/app");
const { cert } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const fs = require("fs");

const serviceAccount = require("./sua-chave-privada.json");

initializeApp({
  credential: cert(serviceAccount),
});

const db = getFirestore();

async function exportarBancoCompleto() {
  try {
    const dadosFinais = {};

    // Lista de coleções/subcoleções que você quer buscar no banco inteiro
    // Adicionei 'users', 'backups' e 'data' baseado na sua imagem
    const colecoesAlvo = ["users", "backups", "data"];

    for (const nomeColecao of colecoesAlvo) {
      // O collectionGroup busca todas as coleções com esse nome, não importa onde estejam escondidas
      const snapshot = await db.collectionGroup(nomeColecao).get();

      if (!snapshot.empty) {
        dadosFinais[nomeColecao] = {};
        snapshot.forEach((doc) => {
          // Salva os dados usando o ID do documento
          dadosFinais[nomeColecao][doc.id] = doc.data();
        });
      }
    }

    if (Object.keys(dadosFinais).length === 0) {
      console.log(
        "Nenhum dado foi encontrado em nenhuma das coleções informadas.",
      );
      return;
    }

    fs.writeFileSync("banco_dados.json", JSON.stringify(dadosFinais, null, 2));
    console.log(
      "Exportação concluída com sucesso! Arquivo banco_dados.json gerado.",
    );
  } catch (erro) {
    console.error("Erro ao exportar dados:", erro);
  }
}

exportarBancoCompleto();
