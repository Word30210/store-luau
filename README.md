# store-luau

**store-luau**는 값과 상태를 관리하기 위해 만들어진 모듈입니다.

# APIS
## `.GetStore(storeId: string?): Store`
- storeId로 생성된 Store가 이미 존재한다면 그것을 반환, 없다면 새로 만들어줍니다.
- 만약 파라미터로 받은 storeId가 없다면, 익명 Store를 만들어서 반환합니다.

```lua
local Store = require(path.to.store)

local myStore = Store.GetStore() -- 익명 Store를 만들어 줍니다.

myStore.test = "Hello, world!" -- Store의 test에 "Hello, world!"를 할당합니다다.

print(myStore.test)
```

```lua
-- shared1.luau
local Store = require(path.to.store)

local sharedStore = Store.GetStore("shared") -- shared라는 id를 가진 Store를 가져옵니다.

sharedStore.test = "Hello, world!" -- sharedStore.test에 "Hello, world!"를 할당합니다.
```

```lua
local Store = require(path.to.store)

local sharedStore = Store.GetStore("shared") -- shared라는 id를 가진 Store를 가져옵니다.

repeat task.wait() until sharedStore.test -- sharedStore.test에 값이 할당될 때 까지 기다립니다.

print(sharedStore.test) -- "Hello, world!"를 출력합니다.
```

## `Store:Register(storeKey: string, targetTable: { [any]: any }, targetKey: string?): Store`
- `Store[storeKey]`의 값이 수정될 때, `targetTable[targetKey or storeKey]`의 값도 같이 수정해줍니다.

```lua
local Store = require(path.to.store)

local myStore, myTable = Store.GetStore(), {}

myStore:Register("store_key", targetTable, "target_key1") -- myStore에 targetTable을 등록합니다.
myStore:Register("store_key", targetTable, "target_key2") -- myStore에 같은 store_key에 여러번 등록 가능합니다.

myStore.store_key = "Hello, world!" -- myStore.store_key에 "Hello, world!"를 할당합니다.

print(targetTable.target_key1, targetTable.target_key2) -- "Hello, world!"를 2번 출력합니다.
```

## `Store:Unregister(storeKey: string, targetTable: { [any]: any }, targetKey: string?): Store`
- `Store:Register()`로 등록했던걸 취소합니다.

## `Store:Observe(storeKey: string, observeFunction: (newValue: any, oldValue: any) -> ()): Store`
- Store의 특정 값이 수정되는것을 감지합니다.

```lua
local Store = require(path.to.store)

local myStore = Store.GetStore()

myStore:Observe("test", function(
    newValue: any,
    oldValue: any
)
    print("test: " .. oldValue .. " -> " .. newValue)
end)

myStore.test = "Hello, world!"
myStore.test = "Bye, world!"

-- "Hello, world!"를 출력하고 "Bye, world!"를 출력합니다.
```

## `Store:ObserveAll(observeFunction: (storeKey: string, newValue: any, oldValue: any) -> ()): Store`
- Store의 값이 수정되는것을 감지합니다.

## `Store:Trigger(storeKey: string): Store`
- Store 값 변경 없이, `ObserveFunction`들을 실행시켜줍니다. 이때, `ObserveFunction`의 인자에는 전부 `nil`이 들어옵니다.

## `Store:Each(eachFunction: (key: string, value: string)): Store`
- Store에 들어 있는 모든 값들을 읽습니다.

## `Store:EachAsync(eachFunction: (key: string, value: string)): Store`
- `Store:Each()`의 비동기 버전입니다.

## `Store:WaitForChange(storeKey: string): (any, any)`
- Store의 값이 바뀔때 까지 기다리고, `newValue`와 `oldValue`를 반환해줍니다.

## `Store:WaitForValue<T>(storeKey: string, value: T): (T, any)`
- Store의 값이 특정 값이 될때까지 기다리고, `newValue`와 `oldValue`를 반환해줍니다.

# TODO LIST
- `Store:Tween(storeKey: string, tweenInfo: TweenInfo, goal: any)` 만들기(Quad의 AdvancedTween을 참고하여, `Store`에 있는 값 트윈시키기)