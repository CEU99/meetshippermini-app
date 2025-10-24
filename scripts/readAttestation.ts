import { EAS, SchemaEncoder } from "@ethereum-attestation-service/eas-sdk";
import { ethers } from "ethers";
import * as dotenv from "dotenv";
dotenv.config({ path: ".env.local" }); // kesin bu dosyayı okur

async function readAttestation() {
  // RPC & signer
  const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);

  // EAS kontrat adresi (Base Mainnet)
  const eas = new EAS(process.env.NEXT_PUBLIC_EAS_CONTRACT!);
  eas.connect(signer);

  // UID (Attestation UID'ni buraya koy)
  const uid = "0xb3ca1823d2493319ba61e82a0c77a9ed655c5c2cadbc5872e8015e5826ed0c7b";

  console.log("🔍 Attestation okunuyor:", uid);

  // Attestation verisini al
  const attestation = await eas.getAttestation(uid);
  console.log("✅ Ham Attestation:", attestation);

  // Schema çözümü için encoder
  const schemaEncoder = new SchemaEncoder("string username, address wallet");
  const decodedData = schemaEncoder.decodeData(attestation.data);

  console.log("\n📦 Çözümlenmiş Attestation Verisi:");
  console.log({
    recipient: attestation.recipient,
    attester: attestation.attester,
    time: new Date(Number(attestation.time) * 1000).toLocaleString(),
    decodedData,
  });
}

readAttestation().catch(console.error);