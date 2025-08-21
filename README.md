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

1. 局部函数
2. 全局函数

有两种参数传递方式：

1. 按值传递参数

```typescript
@Builder function overBuilder(paramA1: string) {
  Row() {
    Text(`UseStateVarByValue: ${paramA1} `)
  }
}
@Entry
@Component
struct Parent {
  @State label: string = 'Hello';
  build() {
    Column() {
      overBuilder(this.label)
    }
  }
}
```

2. 按引用传递

```typescript
class Tmp {
  paramA1: string = '';
}

@Builder
function overBuilder(params: Tmp) {
  Row() {
    Text(`UseStateVarByReference: ${params.paramA1} `)
  }
}

@Entry
@Component
struct Parent {
  @State label: string = 'Hello';

  build() {
    Column() {
      // 在父组件中调用overBuilder组件时，
      // 把this.label通过引用传递的方式传给overBuilder组件。
      overBuilder({ paramA1: this.label })
      Button('Click me').onClick(() => {
        // 单击Click me后，UI文本从Hello更改为ArkUI。
        this.label = 'ArkUI';
      })
    }
  }
}
```

@Builder按引用传递且仅传入一个参数时，才会触发动态渲染UI

当通过引用传递方式向@Builder传递参数时，若参数为@Local装饰的对象，对该对象进行整体赋值会触发@Builder中UI刷新。

@Builder支持状态变量刷新：通过使用UIUtils.makeBinding()函数、Binding类和MutableBinding类实现@Builder函数中状态变量的刷新

```typescript
import { Binding, MutableBinding, UIUtils } from '@kit.ArkUI';

@ObservedV2
class ClassA {
  @Trace props: string = 'Hello';
}

@Builder
function CustomButton(num1: Binding<number>, num2: MutableBinding<number>) {
  Row() {
    Column() {
      Text(`number1 === ${num1.value},  number2 === ${num2.value}`)
        .width(300)
        .height(40)
        .margin(10)
        .backgroundColor('#0d000000')
        .fontColor('#e6000000')
        .borderRadius(20)
        .textAlign(TextAlign.Center)

      Button(`only change number2`)
        .onClick(() => {
          num2.value += 1;
        })
    }
  }
}

@Builder
function CustomButtonObj(obj1: MutableBinding<ClassA>) {
  Row() {
    Column() {
      Text(`props === ${obj1.value.props}`)
        .width(300)
        .height(40)
        .margin(10)
        .backgroundColor('#0d000000')
        .fontColor('#e6000000')
        .borderRadius(20)
        .textAlign(TextAlign.Center)

      Button(`change props`)
        .onClick(() => {
          obj1.value.props += 'Hi';
        })
    }
  }
}

@Entry
@ComponentV2
struct Single {
  @Local number1: number = 5;
  @Local number2: number = 12;
  @Local classA: ClassA = new ClassA();

  build() {
    Column() {
      Button(`change both number1 and number2`)
        .onClick(() => {
          this.number1 += 1;
          this.number2 += 2;
        })
      Text(`number1 === ${this.number1}`)
        .width(300)
        .height(40)
        .margin(10)
        .backgroundColor('#0d000000')
        .fontColor('#e6000000')
        .borderRadius(20)
        .textAlign(TextAlign.Center)
      Text(`number2 === ${this.number2}`)
        .width(300)
        .height(40)
        .margin(10)
        .backgroundColor('#0d000000')
        .fontColor('#e6000000')
        .borderRadius(20)
        .textAlign(TextAlign.Center)
      CustomButton(
        UIUtils.makeBinding<number>(() => this.number1),
        UIUtils.makeBinding<number>(
          () => this.number2,
          (val: number) => {
            this.number2 = val;
          })
      )
      Text(`classA.props === ${this.classA.props}`)
        .width(300)
        .height(40)
        .margin(10)
        .backgroundColor('#0d000000')
        .fontColor('#e6000000')
        .borderRadius(20)
        .textAlign(TextAlign.Center)
      CustomButtonObj(
        UIUtils.makeBinding<ClassA>(
          () => this.classA,
          (val: ClassA) => {
            this.classA = val;
          })
      )
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
```

使用@ComponentV2装饰器触发动态刷新

在@ComponentV2装饰器装饰的自定义组件中配合@ObservedV2和@Trace装饰器，通过按值传递的方式可以实现UI刷新功能。

在@Builder内创建自定义组件传递参数不刷新问题

在parentBuilder函数中创建自定义组件HelloComponent，传递参数为class对象并修改对象内的值时，UI不会触发刷新功能。

【反例】

```typescript
class Tmp {
  name: string = 'Hello';
  age: number = 16;
}

@Builder
function parentBuilder(params: Tmp) {
  Row() {
    Column() {
      Text(`parentBuilder===${params.name}===${params.age}`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      // 此写法不属于按引用传递方式，用法错误导致UI不刷新。
      HelloComponent({ info: params })
    }
  }
}

@Component
struct HelloComponent {
  @Prop info: Tmp = new Tmp();

  build() {
    Row() {
      Text(`HelloComponent===${this.info.name}===${this.info.age}`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
    }
  }
}

@Entry
@Component
struct ParentPage {
  @State nameValue: string = '张三';
  @State ageValue: number = 18;

  build() {
    Column() {
      parentBuilder({ name: this.nameValue, age: this.ageValue })
      Button('Click me')
        .onClick(() => {
          // 此处修改内容时，不会引起HelloComponent处的变化
          this.nameValue = '李四';
          this.ageValue = 20;
        })
    }
    .height('100%')
    .width('100%')
  }
}
```

在parentBuilder函数中创建自定义组件HelloComponent，传递参数为对象字面量形式并修改对象内的值时，UI触发刷新功能。

【正例】

```typescript
class Tmp {
  name: string = 'Hello';
  age: number = 16;
}

@Builder
function parentBuilder(params: Tmp) {
  Row() {
    Column() {
      Text(`parentBuilder===${params.name}===${params.age}`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      // 将整个对象拆分开变成简单类型，属于按引用传递方式，更改属性能够触发UI刷新。
      HelloComponent({ childName: params.name, childAge: params.age })
    }
  }
}

@Component
struct HelloComponent {
  @Prop childName: string = '';
  @Prop childAge: number = 0;

  build() {
    Row() {
      Text(`HelloComponent===${this.childName}===${this.childAge}`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
    }
  }
}

@Entry
@Component
struct ParentPage {
  @State nameValue: string = '张三';
  @State ageValue: number = 18;

  build() {
    Column() {
      parentBuilder({ name: this.nameValue, age: this.ageValue })
      Button('Click me')
        .onClick(() => {
          // 此处修改内容时，会引起HelloComponent处的变化
          this.nameValue = '李四';
          this.ageValue = 20;
        })
    }
    .height('100%')
    .width('100%')
  }
}
```

@Builder方法定义时使用MutableBinding，构造时没有给MutableBinding类型参数传递set访问器，触发set访问器会造成运行时错误。

正确使用方法

```typescript
import { Binding, MutableBinding, UIUtils } from '@kit.ArkUI';

@Builder
function CustomButton(num2: MutableBinding<number>) {
  // CustomButton的第二个参数为MutableBinding，一个可变数据绑定的泛型类
  Row() {
    Button(`Custom Button: ${num2.value}`)
      .onClick(() => {
        // 可变数据绑定的泛型类可以修改绑定的值
        num2.value += 1;
      })
  }
}

@Entry
@ComponentV2
struct CompV2 {
  @Local number1: number = 5;
  @Local number2: number = 10;

  build() {
    Column() {
      Text('parent component')

      CustomButton(
        UIUtils.makeBinding<number>(
          () => this.number2, // GetterCallback
          (val: number) => {
            this.number2 = val;
          }) // SetterCallback 必须提供，否则触发时会造成运行时错误
      )
    }
  }
}
```

不使用MutableBinding的情况下，在@Builder装饰的函数内部修改参数值，修改不会生效且可能造成运行时错误。

###### @LocalBuilder装饰器： 维持组件关系

@LocalBuilder拥有和局部@Builder相同的功能，且比局部@Builder能够更好的确定组件的父子关系和状态管理的父子关系。

定义语法：

```typescript
@LocalBuilder myBuilderFunction() { ... }
```

使用方法

```typescript
this.myBuilderFunction()
```

限制条件

- @LocalBuilder只能在所属组件内声明，不允许全局声明。
- @LocalBuilder不能与内置装饰器或自定义装饰器一起使用。
- 在自定义组件中，@LocalBuilder不能用来装饰静态函数。

@LocalBuilder和@Builder区别说明

当函数componentBuilder被@Builder修饰时，显示效果为“Child”；当函数componentBuilder被@LocalBuilder修饰时，显示效果是“Parent”。

说明：

@Builder componentBuilder()通过this.componentBuilder的形式传给子组件@BuilderParam customBuilderParam，this指向子组件Child的实例。

@LocalBuilder componentBuilder()通过this.componentBuilder的形式传给子组件@BuilderParam customBuilderParam，this指向父组件Parent的实例。

```typescript
@Component
struct Child {
  label: string = 'Child';
  @BuilderParam customBuilderParam: () => void;

  build() {
    Column() {
      this.customBuilderParam()
    }
  }
}

@Entry
@Component
struct Parent {
  label: string = 'Parent';

  @Builder componentBuilder() {
    Text(`${this.label}`)
  }

  // @LocalBuilder componentBuilder() {
  //   Text(`${this.label}`)
  // }

  build() {
    Column() {
      Child({ customBuilderParam: this.componentBuilder })
    }
  }
}
```

