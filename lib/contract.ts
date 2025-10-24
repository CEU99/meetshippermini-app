import { getContract } from 'viem'
import { usePublicClient, useWalletClient } from 'wagmi'
import { wagmiConfig } from './wagmi'
import contractData from '@/contracts/contracts:MeetShipperRegistry.json'

// Contract configuration
export const MEETSHIPPER_CONTRACT = {
  address: contractData.address as `0x${string}`,
  abi: contractData.abi,
  chainId: contractData.network.chainId,
} as const

/**
 * Get a viem contract instance for MeetShipperRegistry
 * This function auto-detects the network from wagmiConfig
 *
 * @param chainId - Optional chain ID to use (defaults to Base Sepolia)
 * @returns A viem contract instance
 */
export function getMeetShipperContract(chainId?: number) {
  const targetChainId = chainId || MEETSHIPPER_CONTRACT.chainId
  const chain = wagmiConfig.chains.find(c => c.id === targetChainId)

  if (!chain) {
    throw new Error(`Chain ${targetChainId} not configured in wagmiConfig`)
  }

  const transport = wagmiConfig.transports[targetChainId]

  if (!transport) {
    throw new Error(`No transport configured for chain ${targetChainId}`)
  }

  return {
    address: MEETSHIPPER_CONTRACT.address,
    abi: MEETSHIPPER_CONTRACT.abi,
    chain,
    chainId: targetChainId,
  }
}

/**
 * Hook to get a public client for reading contract data
 */
export function useMeetShipperContract() {
  const publicClient = usePublicClient({ chainId: MEETSHIPPER_CONTRACT.chainId })
  const { data: walletClient } = useWalletClient({ chainId: MEETSHIPPER_CONTRACT.chainId })

  const contractConfig = getMeetShipperContract()

  return {
    publicClient,
    walletClient,
    contract: contractConfig,
  }
}

// ============================================================================
// READ FUNCTIONS - Examples for reading contract data
// ============================================================================

/**
 * Example: Read the Farcaster username linked to a wallet address
 *
 * @param address - The wallet address to query
 * @returns The linked Farcaster username or empty string if not linked
 *
 * @example
 * ```typescript
 * import { usePublicClient } from 'wagmi'
 *
 * const publicClient = usePublicClient({ chainId: 84532 })
 * const username = await getUsername(publicClient, '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb')
 * console.log('Username:', username)
 * ```
 */
export async function getUsername(
  publicClient: any,
  address: `0x${string}`
): Promise<string> {
  if (!publicClient) {
    throw new Error('Public client not available')
  }

  try {
    const username = await publicClient.readContract({
      address: MEETSHIPPER_CONTRACT.address,
      abi: MEETSHIPPER_CONTRACT.abi,
      functionName: 'getUsername',
      args: [address],
    })

    return username as string
  } catch (error) {
    console.error('Error reading username:', error)
    throw error
  }
}

/**
 * Alternative: Read username directly from the usernames mapping
 * This is functionally equivalent to getUsername but accesses the public mapping directly
 */
export async function getUsernameFromMapping(
  publicClient: any,
  address: `0x${string}`
): Promise<string> {
  if (!publicClient) {
    throw new Error('Public client not available')
  }

  try {
    const username = await publicClient.readContract({
      address: MEETSHIPPER_CONTRACT.address,
      abi: MEETSHIPPER_CONTRACT.abi,
      functionName: 'usernames',
      args: [address],
    })

    return username as string
  } catch (error) {
    console.error('Error reading username from mapping:', error)
    throw error
  }
}

// ============================================================================
// WRITE FUNCTIONS - Examples for writing to the contract
// ============================================================================

/**
 * Example: Link a Farcaster username to the caller's wallet address
 * This is a write operation that requires a wallet signature
 *
 * @param walletClient - The wallet client from wagmi
 * @param farcasterUsername - The Farcaster username to link
 * @returns The transaction hash
 *
 * @example
 * ```typescript
 * import { useWalletClient } from 'wagmi'
 *
 * const { data: walletClient } = useWalletClient({ chainId: 84532 })
 * const txHash = await linkUsername(walletClient, 'myusername')
 * console.log('Transaction hash:', txHash)
 * ```
 */
export async function linkUsername(
  walletClient: any,
  farcasterUsername: string
): Promise<`0x${string}`> {
  if (!walletClient) {
    throw new Error('Wallet client not available. Please connect your wallet.')
  }

  if (!farcasterUsername || farcasterUsername.trim() === '') {
    throw new Error('Farcaster username cannot be empty')
  }

  try {
    const { request } = await walletClient.simulateContract({
      address: MEETSHIPPER_CONTRACT.address,
      abi: MEETSHIPPER_CONTRACT.abi,
      functionName: 'linkUsername',
      args: [farcasterUsername],
      account: walletClient.account,
    })

    const hash = await walletClient.writeContract(request)

    return hash
  } catch (error) {
    console.error('Error linking username:', error)
    throw error
  }
}

/**
 * Example: Link username and wait for transaction confirmation
 *
 * @param walletClient - The wallet client from wagmi
 * @param publicClient - The public client to wait for transaction
 * @param farcasterUsername - The Farcaster username to link
 * @returns Object containing transaction hash and receipt
 *
 * @example
 * ```typescript
 * import { useWalletClient, usePublicClient } from 'wagmi'
 *
 * const { data: walletClient } = useWalletClient({ chainId: 84532 })
 * const publicClient = usePublicClient({ chainId: 84532 })
 *
 * const result = await linkUsernameAndWait(walletClient, publicClient, 'myusername')
 * console.log('Transaction confirmed:', result.receipt.status)
 * ```
 */
export async function linkUsernameAndWait(
  walletClient: any,
  publicClient: any,
  farcasterUsername: string
) {
  const hash = await linkUsername(walletClient, farcasterUsername)

  const receipt = await publicClient.waitForTransactionReceipt({
    hash,
    confirmations: 1,
  })

  return {
    hash,
    receipt,
  }
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * Check if a wallet address has a linked username
 */
export async function hasLinkedUsername(
  publicClient: any,
  address: `0x${string}`
): Promise<boolean> {
  const username = await getUsername(publicClient, address)
  return username !== ''
}

/**
 * Get contract info for display purposes
 */
export function getContractInfo() {
  return {
    name: contractData.name,
    address: MEETSHIPPER_CONTRACT.address,
    network: contractData.network.chain,
    chainId: MEETSHIPPER_CONTRACT.chainId,
  }
}
