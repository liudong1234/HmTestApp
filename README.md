## 学习开发笔记

## 一、UI范式

### 基本语法

#### 装饰器：

- @Entry
- @Component
- @State

- @Builder/@BuilderParam：特殊的封装UI描述的方法，细粒度的封装和复用UI描述。
- @Extend/@Styles：扩展系统组件和封装属性样式，更灵活地组合系统组件。

#### 配置事件

事件方法以“.”链式调用的方式配置系统组件支持的事件，建议每个事件方法单独写一行。

使用组件的成员函数配置组件的事件方法，需要bind this。ArkTS语法不建议使用成员函数配合bind this来配置组件的事件方法。

```typescript
myClickHandler(): void {
  this.counter += 2;
}
...
Button('add counter')
  .onClick(this.myClickHandler.bind(this))
```

使用声明的箭头函数时可以直接调用，不需要bind this。

```typescript
fn = () => {  
    console.info(`counter: ${this.counter}`) 
    this.counter++
}
...
Button('add counter')
    .onClick(this.fn)
```

#### 自定义组件

##### 创建组件

```typescript
@Component
struct HelloComponent {
  @State message: string = 'Hello, World!';

  build() {
    // HelloComponent自定义组件组合系统组件Row和Text
    Row() {
      Text(this.message)
        .onClick(() => {
          // 状态变量message的改变驱动UI刷新，UI从'Hello, World!'刷新为'Hello, ArkUI!'
          this.message = 'Hello, ArkUI!';
        })
    }
  }
}
```

> 如果在其他文件中引用自定义组件，需要使用export关键字导出组件，并在使用的页面import该自定义组件。

@Entry装饰的自定义组件将作为UI页面的入口。在单个UI页面中，仅允许存在一个由@Entry装饰的自定义组件作为页面的入口。@Entry可以接受一个可选的LocalStorage的参数。

##### 组件生命周期

1. aboutToAppear:build函数之前执行
2. onDidBuild:在build函数完成之后进行
3. aboutToDisappear: 组件销毁之前执行

![img](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyPub/011/111/111/0000000000011111111.20250820084745.80424187280311899336960025005691:50001231000000:2800:1317DA2735D64AA0E9944858ECF8661C8E35BDCF923ADE4C1F35274EA2BF5A79.png)

##### 自定义布局

1. onMeasureSize:组件每次布局时触发，计算子组件的尺寸，其执行时间先于onPlaceChildren。
2. onPlaceChildren:组件每次布局时触发，设置子组件的起始位置。

```typescript
// xxx.ets
@Entry
@Component
struct Index {
  build() {
    Column() {
      CustomLayout({ builder: ColumnChildren })
    }
  }
}

// 通过builder的方式传递多个组件，作为自定义组件的一级子组件（即不包含容器组件，如Column）
@Builder
function ColumnChildren() {
  ForEach([1, 2, 3], (index: number) => { // 暂不支持lazyForEach的写法
    Text('S' + index)
      .fontSize(30)
      .width(100)
      .height(100)
      .borderWidth(2)
      .offset({ x: 10, y: 20 })
  })
}

@Component
struct CustomLayout {
  @Builder
  doNothingBuilder() {
  };

  @BuilderParam builder: () => void = this.doNothingBuilder;
  @State startSize: number = 100;
  result: SizeResult = {
    width: 0,
    height: 0
  };

  // 第一步：计算各子组件的大小
  onMeasureSize(selfLayoutInfo: GeometryInfo, children: Array<Measurable>, constraint: ConstraintSizeOptions) {
    let size = 100;
    children.forEach((child) => {
      let result: MeasureResult = child.measure({ minHeight: size, minWidth: size, maxWidth: size, maxHeight: size })
      size += result.width / 2;
    })
    // this.result在该用例中代表自定义组件本身的大小，onMeasureSize方法返回的是组件自身的尺寸。
    this.result.width = 100;
    this.result.height = 400;
    return this.result;
  }
  // 第二步：放置各子组件的位置
  onPlaceChildren(selfLayoutInfo: GeometryInfo, children: Array<Layoutable>, constraint: ConstraintSizeOptions) {
    let startPos = 300;
    children.forEach((child) => {
      let pos = startPos - child.measureResult.height;
      child.layout({ x: pos, y: pos })
    })
  }

  build() {
    this.builder()
  }
}
```

##### 组件成员属性访问限定符使用限制

1. @State/@Prop/@Provide/@BuilderParam/：可以被外部初始化，也可以使用本地值进行初始化
2. @StorageLink/@StorageProp/@LocalStorageLink/@LocalStorageProp/@Consume:不可以被外部初始化
3. @Link/@ObjectLink:必须被外部初始化，禁止本地初始化。
4. @Require含义是当前被@Require装饰的变量必须被外部初始化

##### 组件拓展

ArkUI通过**@Builder**装饰器为开发者提供代码精简解决方案，该装饰器不仅能通过模块化封装简化UI开发流程，还衍生出**@BuilderParam装饰器**、@LocalBuilder装饰器和**wrapBuilder**

###### @Builder装饰器：自定义构建函数

