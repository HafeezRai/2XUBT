# SafeMath.sol

View Source: [openzeppelin-solidity/contracts/math/SafeMath.sol](../openzeppelin-solidity/contracts/math/SafeMath.sol)

**SafeMath**

Wrappers over Solidity's arithmetic operations with added overflow
checks.
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
in bugs, because programmers usually assume that an overflow raises an
error, which is the standard behavior in high level programming languages.
`SafeMath` restores this intuition by reverting the transaction when an
operation overflows.
 * Using this library instead of the unchecked operations eliminates an entire
class of bugs, so it's recommended to use it always.

## Functions

- [add(uint256 a, uint256 b)](#add)
- [sub(uint256 a, uint256 b)](#sub)
- [sub(uint256 a, uint256 b, string errorMessage)](#sub)
- [mul(uint256 a, uint256 b)](#mul)
- [div(uint256 a, uint256 b)](#div)
- [div(uint256 a, uint256 b, string errorMessage)](#div)
- [mod(uint256 a, uint256 b)](#mod)
- [mod(uint256 a, uint256 b, string errorMessage)](#mod)

### add

Returns the addition of two unsigned integers, reverting on
overflow.
     * Counterpart to Solidity's `+` operator.
     * Requirements:
- Addition cannot overflow.

```js
function add(uint256 a, uint256 b) internal pure
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| a | uint256 |  | 
| b | uint256 |  | 

### sub

Returns the subtraction of two unsigned integers, reverting on
overflow (when the result is negative).
     * Counterpart to Solidity's `-` operator.
     * Requirements:
- Subtraction cannot overflow.

```js
function sub(uint256 a, uint256 b) internal pure
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| a | uint256 |  | 
| b | uint256 |  | 

### sub

Returns the subtraction of two unsigned integers, reverting with custom message on
overflow (when the result is negative).
     * Counterpart to Solidity's `-` operator.
     * Requirements:
- Subtraction cannot overflow.
     * _Available since v2.4.0._

```js
function sub(uint256 a, uint256 b, string errorMessage) internal pure
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| a | uint256 |  | 
| b | uint256 |  | 
| errorMessage | string |  | 

### mul

Returns the multiplication of two unsigned integers, reverting on
overflow.
     * Counterpart to Solidity's `*` operator.
     * Requirements:
- Multiplication cannot overflow.

```js
function mul(uint256 a, uint256 b) internal pure
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| a | uint256 |  | 
| b | uint256 |  | 

### div

Returns the integer division of two unsigned integers. Reverts on
division by zero. The result is rounded towards zero.
     * Counterpart to Solidity's `/` operator. Note: this function uses a
`revert` opcode (which leaves remaining gas untouched) while Solidity
uses an invalid opcode to revert (consuming all remaining gas).
     * Requirements:
- The divisor cannot be zero.

```js
function div(uint256 a, uint256 b) internal pure
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| a | uint256 |  | 
| b | uint256 |  | 

### div

Returns the integer division of two unsigned integers. Reverts with custom message on
division by zero. The result is rounded towards zero.
     * Counterpart to Solidity's `/` operator. Note: this function uses a
`revert` opcode (which leaves remaining gas untouched) while Solidity
uses an invalid opcode to revert (consuming all remaining gas).
     * Requirements:
- The divisor cannot be zero.
     * _Available since v2.4.0._

```js
function div(uint256 a, uint256 b, string errorMessage) internal pure
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| a | uint256 |  | 
| b | uint256 |  | 
| errorMessage | string |  | 

### mod

Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
Reverts when dividing by zero.
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
opcode (which leaves remaining gas untouched) while Solidity uses an
invalid opcode to revert (consuming all remaining gas).
     * Requirements:
- The divisor cannot be zero.

```js
function mod(uint256 a, uint256 b) internal pure
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| a | uint256 |  | 
| b | uint256 |  | 

### mod

Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
Reverts with custom message when dividing by zero.
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
opcode (which leaves remaining gas untouched) while Solidity uses an
invalid opcode to revert (consuming all remaining gas).
     * Requirements:
- The divisor cannot be zero.
     * _Available since v2.4.0._

```js
function mod(uint256 a, uint256 b, string errorMessage) internal pure
returns(uint256)
```

**Arguments**

| Name        | Type           | Description  |
| ------------- |------------- | -----|
| a | uint256 |  | 
| b | uint256 |  | 
| errorMessage | string |  | 

## Contracts

* [CFD](CFD.md)
* [Context](Context.md)
* [DAITokenMock](DAITokenMock.md)
* [DownDai](DownDai.md)
* [ERC20](ERC20.md)
* [ERC20Burnable](ERC20Burnable.md)
* [ERC20Detailed](ERC20Detailed.md)
* [ERC20Mintable](ERC20Mintable.md)
* [IERC20](IERC20.md)
* [IMakerMedianizer](IMakerMedianizer.md)
* [IUniswapExchange](IUniswapExchange.md)
* [IUniswapFactory](IUniswapFactory.md)
* [MakerMedianizerMock](MakerMedianizerMock.md)
* [Migrations](Migrations.md)
* [MinterRole](MinterRole.md)
* [Ownable](Ownable.md)
* [Roles](Roles.md)
* [SafeMath](SafeMath.md)
* [StableMath](StableMath.md)
* [UpDai](UpDai.md)
* [UpSideDai](UpSideDai.md)
