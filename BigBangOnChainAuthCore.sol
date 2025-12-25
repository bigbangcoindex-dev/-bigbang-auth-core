// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BigBangOnChainAuth Core (v0.1 - FROZEN)
 * @author BigBang
 *
 * @notice
 * Core on-chain authentication logic for the BigBang protocol.
 * This contract represents the immutable base layer and is designed
 * strictly for inheritance by future protocol versions.
 *
 * @dev
 * =========================
 *  PROTOCOL VERSION: v0.1
 * =========================
 * THIS CONTRACT IS FROZEN.
 * NO BUSINESS LOGIC SHOULD BE MODIFIED.
 * ONLY INHERITANCE IS ALLOWED.
 */
 import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


abstract contract BigBangOnChainAuthCore {
    using SafeERC20 for IERC20;
    /*//////////////////////////////////////////////////////////////
                                TYPES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice
     * Represents a project manager authorized by the protocol.
     *
     * @param managerAddress Wallet address of the manager
     * @param secret Manager-specific secret used for identity hash derivation
     * @param isActive Indicates whether the manager is currently active
     * @param proofWindowSeconds Time window used for time-bound key generation
     */
    struct Manager {
        address managerAddress;
        bytes32 secret;
        bool isActive;
        uint256 proofWindowSeconds;
    }

    /**
     * @notice
     * Represents a registered user identity under a specific manager.
     *
     * @param wallet User wallet address
     * @param username Chosen username (unique per manager)
     * @param status Indicates whether the identity is active or blocked
     */
    struct Identity {
        address wallet;
        string username;
        bool status;
    }

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when a new manager is registered
     */
    event ManagerRegistered(address indexed manager, string message);

    /**
     * @notice Emitted when a manager is deactivated
     */
    event ManagerDeactivated(address indexed manager, string message);

    /**
     * @notice Emitted when a new user identity is registered
     */
    event UserRegistered(
        address indexed manager,
        address indexed wallet,
        bytes32 identityHash,
        string username
    );
    /// @notice Emitted when manager registration fee is updated by Root
/// @param root The root address who applied the change
/// @param oldFee Previous manager registration fee
/// @param newFee New manager registration fee
    event ManagerRegistrationFeeUpdated(
      address indexed root,
      uint256 oldFee,
      uint256 newFee
   );


    /**
     * @notice Emitted when a manager updates the proof window duration
     */
    event ProofWindowUpdated(address indexed manager, uint256 windowSeconds);

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Root address with super-administrative privileges
     */
    address public root;
    

    /**
     * @notice Total count of registered accounts (managers + users)
     */
    uint256 internal totalAccounts;
    uint256 public  MANAGER_REG_FEE = 15 * 1e18; // 15 BBG
    address public bigBangToken;

    /**
     * @notice Mapping of manager address to Manager struct
     */
    mapping(address => Manager) public managers;

    // ========================= PROTOCOL LAW v0.1 =========================

    /**
     * @dev Mapping: manager => identityHash => Identity
     */
    mapping(address => mapping(bytes32 => Identity)) internal identities;

    /**
     * @dev Mapping: manager => username => used
     */
    mapping(address => mapping(string => bool)) internal usernameUsed;

    /**
     * @dev Mapping: manager => wallet => used
     */
    mapping(address => mapping(address => bool)) internal walletUsed;

    /**
     * @dev Mapping of caller address to last generated identity hash
     */
    mapping(address => bytes32) internal HashUser;

    // ===================================================================

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Restricts function access to the root address only
     */
    modifier onlyRoot() {
        require(msg.sender == root, "ONLY_ROOT");
        _;
    }

    /**
     * @notice Restricts function access to active managers only
     */
    modifier onlyActiveManager() {
        require(managers[msg.sender].isActive, "MANAGER_INACTIVE");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        MANAGER LIFECYCLE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deactivates a manager by the root authority
     * @param _manager Address of the manager to deactivate
     */
    function RootDeactivateManagers(address _manager) public onlyRoot {
        require(managers[_manager].isActive, "MANAGER_NOT_ACTIVE");
        managers[_manager].isActive = false;
    }
/**
 * @notice Transfers root ownership to a new address.
 * @dev Can only be called by the current root owner.
 * @param newRootOwner The address of the new root owner.
 */
   function transferRootOwnership(address newRootOwner) external onlyRoot {
       require(newRootOwner != address(0), "BigBang: ZERO_ADDRESS");
       require(newRootOwner != root, "BigBang: SAME_OWNER");
    root = newRootOwner;
   }
   /**
 * @notice Withdraws collected BBG tokens from the protocol treasury.
 * @dev Can only be called by the root owner to fund BigBang development
 *      and infrastructure costs.
 * @param to Destination address that will receive the BBG tokens.
 * @param amount Amount of BBG tokens to withdraw.
 *
 * Requirements:
 * - Caller must be the root owner.
 * - `to` must not be the zero address.
 */
   function withdrawBBG(address to, uint256 amount) external onlyRoot {
       require(to != address(0), "INVALID_ADDRESS");
       IERC20 token = IERC20(bigBangToken);
       require( token.transfer(to, amount),"BBG_WITHDRAW_FAILED");
   }
   /// @notice Updates manager registration fee (can be set to 0 for free onboarding)
/// @dev Only callable by Root
/// @param newFee New fee amount in BBG token units
    function setManagerRegistrationFee(uint256 newFee) external onlyRoot {
       uint256 oldFee = MANAGER_REG_FEE;
       MANAGER_REG_FEE = newFee;

       emit ManagerRegistrationFeeUpdated(
          msg.sender, // ✅ Root اعمال‌کننده
          oldFee,
          newFee
       );
    }

    /**
     * @notice Registers a new manager in the protocol
     * @param _secret Manager-specific secret used for identity hashing
     */
    function RegisterManager(bytes32 _secret) public {
       _validateSecret(_secret);
       require(managers[msg.sender].managerAddress == address(0), "MANAGER_EXISTS");
       IERC20 token = IERC20(bigBangToken);
    // ---- collect fixed BBG fee from manager ----
    if (MANAGER_REG_FEE > 0)
       require( token.transferFrom(msg.sender,address(this), MANAGER_REG_FEE),"BBG_FEE_TRANSFER_FAILED");

    managers[msg.sender] = Manager({
        managerAddress: msg.sender,
        secret: _secret,
        isActive: true,
        proofWindowSeconds: 0
    });

    totalAccounts += 1;

    emit ManagerRegistered(msg.sender, "Created");
}
/**
 * @dev Validates minimum entropy requirements for a manager secret.
 *
 * This function enforces a security floor by rejecting trivially weak secrets
 * (e.g., very short numbers or near-zero values) that could be brute-forced
 * off-chain and compromise derived hashes or OTPs.
 *
 * The validation is format-agnostic and does NOT attempt to measure true
 * randomness. It simply requires a minimum number of non-zero bytes to
 * discourage careless or dangerously weak secret choices.
 *
 * Responsibility Notice:
 * - This check prevents catastrophic secrets.
 * - Full responsibility for generating a high-entropy secret remains with
 *   the manager.
 *
 * @param secret The raw 32-byte secret provided during manager registration.
 */
function _validateSecret(bytes32 secret) internal pure {
    uint256 nonZeroBytes = 0;

    for (uint256 i = 0; i < 32; i++) {
        if (secret[i] != 0x00) {
            nonZeroBytes++;
            if (nonZeroBytes >= 6) {
                return; // early exit once minimum entropy is satisfied
            }
        }
    }

    revert("SECRET_WEAK");
}

    /**
     * @notice Allows a manager to deactivate itself voluntarily
     */
    function selfDeactivate() public onlyActiveManager {
        managers[msg.sender].isActive = false;
        totalAccounts -= 1;
        emit ManagerDeactivated(msg.sender, "It has been dissolved.");
    }

    /**
     * @notice Sets the proof window duration for time-bound key generation
     * @param windowSeconds Length of the proof window in seconds
     */
    function setProofWindow(uint256 windowSeconds) public onlyActiveManager {
        require(windowSeconds >= 1 hours, "WINDOW_TOO_SHORT");
        require(windowSeconds <= 7 days, "WINDOW_TOO_LONG");
        managers[msg.sender].proofWindowSeconds = windowSeconds;
        emit ProofWindowUpdated(msg.sender, windowSeconds);
    }

    /**
     * @notice Blocks a specific user identity under the calling manager
     * @param identityHash Hash of the identity to block
     */
    function blockUser(bytes32 identityHash) public onlyActiveManager {
        require(identities[msg.sender][identityHash].status, "ALREADY_BLOCKED");
        identities[msg.sender][identityHash].status = false;
    }

    /*//////////////////////////////////////////////////////////////
                          USER REGISTRATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Registers a new user identity under a specific manager
     *
     * @param manager Address of the manager
     * @param wallet User wallet address
     * @param username Unique username per manager
     */
    function RegisterUser(
        address manager,
        address wallet,
        string calldata username
    ) public {

        require(managers[manager].isActive, "MANAGER_INACTIVE");
        require(!usernameUsed[manager][username], "USERNAME_USED");
        require(!walletUsed[manager][wallet], "WALLET_USED");

        bytes32 identityHash = keccak256(
            abi.encodePacked(wallet, username, managers[manager].secret)
        );

        require(
            identities[manager][identityHash].wallet == address(0),
            "IDENTITY_EXISTS"
        );

        identities[manager][identityHash] = Identity({
            wallet: wallet,
            username: username,
            status: true
        });

        HashUser[msg.sender] = identityHash;
        usernameUsed[manager][username] = true;
        walletUsed[manager][wallet] = true;

        totalAccounts += 1;
        emit UserRegistered(manager, wallet, identityHash, username);
    }

    /*//////////////////////////////////////////////////////////////
                          READ-ONLY AUTH LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the last stored identity hash for a user address
     * @param user Address to query
     */
    function ShowHashUser(address user) public view returns (bytes32) {
        return HashUser[user];
    }

    /**
     * @notice Returns total number of registered accounts
     */
    function ShowTotalAccount() public view returns (uint256) {
        return totalAccounts;
    }

    /**
     * @notice
     * Verifies an identity and derives a time-bound key for the current window.
     *
     * @dev
     * This function does not store any state and relies entirely on
     * deterministic inputs (identityHash + time index).
     *
     * @param manager Address of the manager
     * @param identityHash Hash of the identity
     */
    
    function verifyIdentityAndGetDailyKey(
    address manager,
    bytes32 identityHash
) public view returns (bytes32) {

    Identity storage user = identities[manager][identityHash];

    require(managers[manager].isActive, "MANAGER_INACTIVE");
    require(user.status, "IDENTITY_INVALID");
    require(identityHash != bytes32(0), "INVALID_IDENTITY_HASH");

    uint256 window = managers[manager].proofWindowSeconds;
    if (window == 0) window = 1 days;

    uint256 timeIndex = block.timestamp / window;

    // Domain-prefixed, project-bound, time-bound OTP
    return keccak256(
        abi.encodePacked(
            "key:",
            identityHash,
            manager,
            timeIndex
        )
    );
}


    /**
     * @notice Validates a provided time-bound key for the current window
     *
     * @param manager Address of the manager
     * @param identityHash Identity hash
     * @param providedKey Key to validate
     */
    function validateDailyKey(
    address manager,
    bytes32 identityHash,
    bytes32 providedKey
) public view returns (bool) {

    Identity storage user = identities[manager][identityHash];

    require(managers[manager].isActive, "MANAGER_INACTIVE");
    require(user.status, "IDENTITY_INVALID");
    require(identityHash != bytes32(0), "INVALID_IDENTITY_HASH");

    uint256 window = managers[manager].proofWindowSeconds;
    if (window == 0) window = 1 days;

    uint256 timeIndex = block.timestamp / window;

    bytes32 expectedKey = keccak256(
        abi.encodePacked(
            "key:",
            identityHash,
            manager,
            timeIndex
        )
    );

    return providedKey == expectedKey;
}

}