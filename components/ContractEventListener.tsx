'use client';

import { useWatchContractEvent } from 'wagmi';
import { useState } from 'react';
import contractData from '@/contracts/MeetShipperRegistry.json';

const CONTRACT_ADDRESS = '0x13c821c62a07d4a6252382939b0afcd2e1527fd4' as const;
const CONTRACT_ABI = contractData.abi;

interface WalletLinkedEvent {
  user: string;
  farcasterUsername: string;
  txHash: string;
}

export default function ContractEventListener() {
  const [events, setEvents] = useState<WalletLinkedEvent[]>([]);

  useWatchContractEvent({
    address: CONTRACT_ADDRESS,
    abi: CONTRACT_ABI,
    eventName: 'WalletLinked',
    onLogs(logs) {
      console.log('📡 New WalletLinked event received:', logs);

      const parsed = logs.map((log: any) => ({
        user: log.args.user as string,
        farcasterUsername: log.args.farcasterUsername as string,
        txHash: log.transactionHash as string,
      }));

      setEvents((prev) => [...parsed, ...prev]);
    },
  });

  return (
    <div className="bg-white border border-gray-200 rounded-lg p-6 mt-6">
      <h2 className="text-lg font-semibold text-gray-900 mb-4">
        🔔 On-Chain Event Listener
      </h2>
      <p className="text-sm text-gray-600 mb-4">
        Dinleyici aktif. Yeni <code>WalletLinked</code> event’leri burada canlı olarak listelenecek.
      </p>

      {events.length === 0 ? (
        <p className="text-sm text-gray-400 italic">Henüz event alınmadı.</p>
      ) : (
        <ul className="divide-y divide-gray-200">
          {events.map((e, i) => (
            <li key={i} className="py-3 text-sm">
              <span className="font-mono text-gray-800">
                {e.user.slice(0, 6)}...{e.user.slice(-4)}
              </span>
              <span className="text-gray-500 ml-2">→</span>
              <span className="text-purple-600 font-medium ml-2">
                {e.farcasterUsername}
              </span>
              <a
                href={`https://basescan.org/tx/${e.txHash}`}
                target="_blank"
                rel="noopener noreferrer"
                className="ml-2 text-blue-500 underline"
              >
                (TX)
              </a>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}