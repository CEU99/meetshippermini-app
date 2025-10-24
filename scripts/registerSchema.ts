import { SchemaRegistry } from "@ethereum-attestation-service/eas-sdk";
import { ethers } from "ethers";
import "dotenv/config";

async function registerSchema() {
  // Provider & signer ayarları
  const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);

  // Base Mainnet adresi (test için Base Sepolia da olur)
  const SCHEMA_REGISTRY_ADDRESS = "0x4200000000000000000000000000000000000020";

  const schemaRegistry = new SchemaRegistry(SCHEMA_REGISTRY_ADDRESS);
  schemaRegistry.connect(signer);

  // Schema tanımı
  const schema = "string username, address wallet";
  const revocable = true;

  console.log("📦 Schema kaydediliyor:", schema);

  // Schema oluşturma
  const tx = await schemaRegistry.register({
    schema,
    revocable,
  });

  console.log("🚀 İşlem gönderildi:", tx);

  // İşlem tamamlanınca receipt al
  const receipt = await tx.wait();
  console.log("✅ Şema kaydı tamamlandı:", receipt);
}

registerSchema().catch(console.error);