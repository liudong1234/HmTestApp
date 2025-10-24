# 学习开发笔记

# ArkTS声明式开发范式

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

1. **按值传递参数**

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

2. **按引用传递**

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

###### @BuilderParam装饰器：引用@Builder函数

为组件添加自定义功能

```typescript
//使用方法
@Builder
function overBuilder() {
}

@Component
struct Child {
  @Builder
  doNothingBuilder() {
  }

  // 使用自定义组件的自定义构建函数初始化@BuilderParam
  @BuilderParam customBuilderParam: () => void = this.doNothingBuilder;
  // 使用全局自定义构建函数初始化@BuilderParam
  @BuilderParam customOverBuilderParam: () => void = overBuilder;

  build() {
  }
}
```

**限制条件**

- 使用@BuilderParam装饰的变量只能通过@Builder函数进行初始化。
- 当@Require装饰器和@BuilderParam装饰器一起使用时，@BuilderParam装饰器必须进行初始化。
- 在自定义组件尾随闭包的场景下，子组件有且仅有一个@BuilderParam用来接收此尾随闭包，且此@BuilderParam装饰的方法不能有参数。

###### wrapBuilder：封装全局@Builder

当在一个struct内使用多个全局@Builder函数实现UI的不同效果时，代码维护将变得非常困难，且页面不够整洁。此时，可以使用wrapBuilder封装全局@Builder。

**限制条件**

1. wrapBuilder方法只能传入全局@Builder方法。
2. wrapBuilder方法返回的WrappedBuilder对象的builder属性方法只能在struct内部使用。

用法

```typescript
@Builder
function MyBuilder(value: string, size: number) {
  Text(value)
    .fontSize(size)
}

let globalBuilder: WrappedBuilder<[string, number]> = wrapBuilder(MyBuilder);

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  build() {
    Row() {
      Column() {
        globalBuilder.builder(this.message, 50)
      }
      .width('100%')
    }
    .height('100%')
  }
}
```

##### @Style装饰器 定义拓展组件样式

**使用说明**

- 当前@Styles仅支持通用属性和通用事件。
- @Styles可以定义在组件内或全局，在全局定义时需在方法名前面添加function关键字，组件内定义时则不需要添加function关键字。
- 组件内@Styles的优先级高于全局@Styles。框架优先找当前组件内的@Styles，如果找不到，则会全局查找。

```typescript
@Entry
@Component
struct FancyUse {
  @State heightValue: number = 50;

  @Styles
  fancy() {
    .height(this.heightValue)
    .backgroundColor(Color.Blue)
    .onClick(() => {
      this.heightValue = 100;
    })
  }

  build() {
    Column() {
      Button('change height')
        .fancy()
    }
    .height('100%')
    .width('100%')
  }
}
```

**限制条件**

- @Styles方法不能有参数，编译期会报错，表明@Styles方法不支持参数。
- 不支持在@Styles方法内使用逻辑组件，逻辑组件内的属性不生效。

```typescript
// 错误写法
@Styles
function backgroundColorStyle() {
  if (true) {
    .backgroundColor(Color.Red)
  }
}

// 正确写法
@Styles
function backgroundColorStyle() {
  .backgroundColor(Color.Red)
}
```

**使用场景**

```typescript
// 定义在全局的@Styles封装的样式
@Styles
function globalFancy () {
  .width(150)
  .height(100)
  .backgroundColor(Color.Pink)
}

@Entry
@Component
struct FancyUse {
  @State heightValue: number = 100;
  // 定义在组件内的@Styles封装的样式
  @Styles fancy() {
    .width(200)
    .height(this.heightValue)
    .backgroundColor(Color.Yellow)
    .onClick(() => {
      this.heightValue = 200;
    })
  }

  build() {
    Column({ space: 10 }) {
      // 使用全局的@Styles封装的样式
      Text('FancyA')
        .globalFancy()
        .fontSize(30)
      // 使用组件内的@Styles封装的样式
      Text('FancyB')
        .fancy()
        .fontSize(30)
    }
  }
}
```

##### @Extend装饰器 定义扩展组件样式

**使用规则**

- 和@Styles不同，@Extend支持封装指定组件的私有属性、私有事件和自身定义的全局方法。

```typescript
// @Extend(Text)可以支持Text的私有属性fontColor
@Extend(Text)
function fancy() {
  .fontColor(Color.Red)
}

// superFancyText可以调用预定义的fancy
@Extend(Text)
function superFancyText(size: number) {
  .fontSize(size)
  .fancy()
}
```

- 和@Styles不同，@Extend装饰的方法支持参数，开发者可以在调用时传递参数，调用遵循TS方法传值调用。

```typescript
// xxx.ets
@Extend(Text)
function fancy(fontSize: number) {
  .fontColor(Color.Red)
  .fontSize(fontSize)
}

@Entry
@Component
struct FancyUse {
  build() {
    Row({ space: 10 }) {
      Text('Fancy')
        .fancy(16)
      Text('Fancy')
        .fancy(24)
    }
  }
}
```

- @Extend装饰的方法的参数可以为function，作为Event事件的句柄。

```typescript
@Extend(Text)
function makeMeClick(onClick: () => void) {
  .backgroundColor(Color.Blue)
  .onClick(onClick)
}

@Entry
@Component
struct FancyUse {
  @State label: string = 'Hello World';

  onClickHandler() {
    this.label = 'Hello ArkUI';
  }

  build() {
    Row({ space: 10 }) {
      Text(`${this.label}`)
        .makeMeClick(() => {
          this.onClickHandler();
        })
    }
  }
}
```

- @Extend的参数可以为状态变量，当状态变量改变时，UI可以正常的被刷新渲染。

```typescript
@Extend(Text)
function fancy(fontSize: number) {
  .fontColor(Color.Red)
  .fontSize(fontSize)
}

@Entry
@Component
struct FancyUse {
  @State fontSizeValue: number = 20

  build() {
    Row({ space: 10 }) {
      Text('Fancy')
        .fancy(this.fontSizeValue)
        .onClick(() => {
          this.fontSizeValue = 30
        })
    }
  }
}
```

**限制条件**

- 和@Styles不同，@Extend仅支持在全局定义，不支持在组件内部定义。
- 仅限在当前文件内使用，不支持导出。

##### stateStyles：多态样式

@Styles仅仅应用于静态页面的样式复用，stateStyles可以依据组件的内部状态的不同，快速设置不同样式

stateStyles是属性方法，可以根据UI内部状态来设置样式，类似于css伪类，但语法不同。ArkUI提供以下五种状态：

- focused：获焦态。
- normal：正常态。
- pressed：按压态。
- disabled：不可用态。
- selected：选中态。

**使用场景**

```typescript
//utton1处于第一个组件，Button2处于第二个组件。按压时显示为pressed态指定的黑色。使用Tab键走焦，Button1获焦并显示为focused态指定的粉色。当Button2获焦的时候，Button2显示为focused态指定的粉色，Button1失焦显示normal态指定的蓝色。
@Entry
@Component
struct StateStylesSample {
  build() {
    Column() {
      Button('Button1')
        .stateStyles({
          focused: {
            .backgroundColor('#ffffeef0')
          },
          pressed: {
            .backgroundColor('#ff707070')
          },
          normal: {
            .backgroundColor('#ff2787d9')
          }
        })
        .margin(20)
      Button('Button2')
        .stateStyles({
          focused: {
            .backgroundColor('#ffffeef0')
          },
          pressed: {
            .backgroundColor('#ff707070')
          },
          normal: {
            .backgroundColor('#ff2787d9')
          }
        })
    }.margin('30%')
  }
}
```

**@Styles和stateStyles联合使用**

以下示例通过@Styles指定stateStyles的不同状态。

```
@Entry
@Component
struct MyComponent {
  @Styles normalStyle() {
    .backgroundColor(Color.Gray)
  }

  @Styles pressedStyle() {
    .backgroundColor(Color.Red)
  }

  build() {
    Column() {
      Text('Text1')
        .fontSize(50)
        .fontColor(Color.White)
        .stateStyles({
          normal: this.normalStyle,
          pressed: this.pressedStyle,
        })
    }
  }
}
```

**在stateStyles里使用常规变量和状态变量**

stateStyles可以通过this绑定组件内的常规变量和状态变量。

```typescript
//Button默认normal态显示绿色，第一次按下Tab键让Button获焦显示为focus态的红色，点击事件触发后，再次按下Tab键让Button获焦，focus态变为粉色。

@Entry
@Component
struct CompWithInlineStateStyles {
  @State focusedColor: Color = Color.Red;
  normalColor: Color = Color.Green;

  build() {
    Column() {
      Button('clickMe')
        .height(100)
        .width(100)
        .stateStyles({
          normal: {
            .backgroundColor(this.normalColor)
          },
          focused: {
            .backgroundColor(this.focusedColor)
          }
        })
        .onClick(() => {
          this.focusedColor = Color.Pink;
        })
        .margin('30%')
    }
  }
}
```

##### @AnimatableExtend装饰器：定义可动画属性

**使用要求**

- @AnimatableExtend仅支持定义在全局，不支持在组件内部定义。
- @AnimatableExtend定义的函数参数类型必须为number类型或者实现 AnimatableArithmetic<T>接口的自定义类型。
- @AnimatableExtend定义的函数体内只能调用@AnimatableExtend括号内组件的属性方法。

```typescript
@AnimatableExtend(Text)
function animatableWidth(width: number) {
  .width(width)
}

@Entry
@Component
struct AnimatablePropertyExample {
  @State textWidth: number = 80;

  build() {
    Column() {
      Text("AnimatableProperty")
        .animatableWidth(this.textWidth)
        .animation({ duration: 2000, curve: Curve.Ease })
      Button("Play")
        .onClick(() => {
          this.textWidth = this.textWidth == 80 ? 160 : 80;
        })
    }.width("100%")
    .padding(10)
  }
}
```

##### @Require装饰器：校验构造传参

@Require是校验@Prop、@State、@Provide、@BuilderParam、@Param和普通变量(无状态装饰器修饰的变量)是否需要构造传参的一个装饰器。

```typescript
@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  @Builder
  buildTest() {
    Row() {
      Text('Hello, world')
        .fontSize(30)
    }
  }

  build() {
    Row() {
      //构造Child、ChildV2组件时没有传参，会导致编译不通过。
      Child()
      ChildV2()
    }
  }
}

@Component
struct Child {
  @Builder
  buildFunction() {
    Column() {
      Text('initBuilderParam')
        .fontSize(30)
    }
  }

  // 使用@Require必须构造时传参。
  @Require regular_value: string = 'Hello';
  @Require @State state_value: string = 'Hello';
  @Require @Provide provide_value: string = 'Hello';
  @Require @BuilderParam initBuildTest: () => void = this.buildFunction;
  @Require @Prop initMessage: string = 'Hello';

  build() {
    Column() {
      Text(this.initMessage)
        .fontSize(30)
      this.initBuildTest();
    }
  }
}

@ComponentV2
struct ChildV2 {
  // 使用@Require必须构造时传参。
  @Require @Param message: string;

  build() {
    Column() {
      Text(this.message)
    }
  }
}
```

##### @Reusable装饰器：组件复用

@Reusable装饰器标记的自定义组件支持视图节点、组件实例和状态上下文的复用，避免重复创建和销毁，提升性能。

**限制条件**

- @Reusable装饰器仅用于自定义组件。
- 被@Reusable装饰的自定义组件在复用时，会递归调用该自定义组件及其所有子组件的aboutToReuse回调函数。若在子组件的aboutToReuse函数中修改了父组件的状态变量，此次修改将不会生效，请避免此类用法。若需设置父组件的状态变量，可使用setTimeout设置延迟执行，将任务抛出组件复用的作用范围，使修改生效。
- ComponentContent不支持传入@Reusable装饰器装饰的自定义组件。

```typescript
import { ComponentContent } from "@kit.ArkUI";

@Builder
function buildCreativeLoadingDialog(closedClick: () => void) {
  Crash()
}

// 如果注释掉就可以正常弹出弹窗，如果加上@Reusable就直接crash。
@Reusable
@Component
export struct Crash {
  build() {
    Column() {
      Text("Crash")
        .fontSize(12)
        .lineHeight(18)
        .fontColor(Color.Blue)
        .margin({
          left: 6
        })
    }.width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';
  private uiContext = this.getUIContext();

  build() {
    RelativeContainer() {
      Text(this.message)
        .id('Index')
        .fontSize(50)
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(() => {
          // ComponentContent底层是BuilderNode，BuilderNode不支持传入@Reusable注解的自定义组件。
          let contentNode = new ComponentContent(this.uiContext, wrapBuilder(buildCreativeLoadingDialog), () => {
          });
          this.uiContext.getPromptAction().openCustomDialog(contentNode);
        })
    }
    .height('100%')
    .width('100%')
  }
}
```

- @Reusable装饰器不建议嵌套使用，会增加内存，降低复用效率，加大维护难度。嵌套使用会导致额外缓存池的生成，各缓存池拥有相同树状结构，复用效率低下。此外，嵌套使用会使生命周期管理复杂，资源和变量共享困难

##### 使用场景

###### 动态布局更新

```typescript
// xxx.ets
export class Message {
  value: string | undefined;

  constructor(value: string) {
    this.value = value;
  }
}

@Entry
@Component
struct Index {
  @State switch: boolean = true;

  build() {
    Column() {
      Button('Hello')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .onClick(() => {
          this.switch = !this.switch;
        })
      if (this.switch) {
        // 如果只有一个复用的组件，可以不用设置reuseId。
        Child({ message: new Message('Child') })
          .reuseId('Child')
      }
    }
    .height("100%")
    .width('100%')
  }
}

@Reusable
@Component
struct Child {
  @State message: Message = new Message('AboutToReuse');

  aboutToReuse(params: Record<string, ESObject>) {
    console.info("Recycle====Child==");
    this.message = params.message as Message;
  }

  build() {
    Column() {
      Text(this.message.value)
        .fontSize(30)
    }
    .borderWidth(1)
    .height(100)
  }
}
```

###### 列表滚动配合LazyForEach使用

```typescript
class MyDataSource implements IDataSource {
  private dataArray: string[] = [];
  private listener: DataChangeListener | undefined;

  public totalCount(): number {
    return this.dataArray.length;
  }

  public getData(index: number): string {
    return this.dataArray[index];
  }

  public pushData(data: string): void {
    this.dataArray.push(data);
  }

  public reloadListener(): void {
    this.listener?.onDataReloaded();
  }

  public registerDataChangeListener(listener: DataChangeListener): void {
    this.listener = listener;
  }

  public unregisterDataChangeListener(listener: DataChangeListener): void {
    this.listener = undefined;
  }
}

@Entry
@Component
struct ReuseDemo {
  private data: MyDataSource = new MyDataSource();

  aboutToAppear() {
    for (let i = 1; i < 1000; i++) {
      this.data.pushData(i + "");
    }
  }

  // ...
  build() {
    Column() {
      List() {
        LazyForEach(this.data, (item: string) => {
          ListItem() {
            CardView({ item: item })
          }
        }, (item: string) => item)
      }
    }
  }
}

// 复用组件
@Reusable
@Component
export struct CardView {
  // 被\@State修饰的变量item才能更新，未被\@State修饰的变量不会更新。
  @State item: string = '';

  aboutToReuse(params: Record<string, Object>): void {
    this.item = params.item as string;
  }

  build() {
    Column() {
      Text(this.item)
        .fontSize(30)
    }
    .borderWidth(1)
    .height(100)
  }
}
```

### 状态管理

装饰器可按数据传递形式和同步类型分为：只读的单向传递和可变更的双向传递。

图示如下，具体装饰器的介绍，可详见管理组件拥有的状态和管理应用拥有的状态。开发者可以利用这些能力来实现数据和UI的联动。

![img](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyPub/011/111/111/0000000000011111111.20250830120106.53228013539434080653391293868526:50001231000000:2800:81E0A577A2576DAC02890A4FE680AA6A65F09CE2EEB08B8F5D57486227BCE0D4.png)

上图中，Components部分的装饰器为组件级别的状态管理，Application部分为应用的状态管理。开发者可以通过@StorageLinkk/@LocalStorageLink实现应用和组件状态的双向同步，通过@StorageProp/@LocalStorageProp实现应用和组件状态的单向同步。

管理组件拥有的状态，即图中Components级别的状态管理：

- @State：@State装饰的变量拥有其所属组件的状态，可以作为其子组件单向和双向同步的数据源。当其数值改变时，会引起相关组件的渲染刷新。
- @Prop：@Prop装饰的变量可以和父组件建立单向同步关系，@Prop装饰的变量是可变的，但修改不会同步回父组件。
- @Link：@Link装饰的变量可以和父组件建立双向同步关系，子组件中@Link装饰变量的修改会同步给父组件中建立双向数据绑定的数据源，父组件的更新也会同步给@Link装饰的变量。
- @Provide/@Consume：@Provide/@Consume装饰的变量用于跨组件层级（多层组件）同步状态变量，可以不需要通过参数命名机制传递，通过alias（别名）或者属性名绑定。
- @Observed：@Observed装饰class，需要观察多层嵌套场景的class需要被@Observed装饰。单独使用@Observed没有任何作用，需要和@ObjectLink、@Prop联用。
- @ObjectLink：@ObjectLink装饰的变量接收@Observed装饰的class的实例，应用于观察多层嵌套场景，和父组件的数据源构建双向同步。

说明

仅@Observed/@ObjectLink可以观察嵌套场景，其他的状态变量仅能观察第一层，详情见各个装饰器章节的“观察变化和行为表现”小节。

管理应用拥有的状态，即图中Application级别的状态管理：

- AppStorage是应用程序中的一个特殊的单例LocalStorage对象，是应用级的数据库，和进程绑定，通过@StorageProp和@StorageLink装饰器可以和组件联动。
- AppStorage是应用状态的“中枢”，将需要与组件（UI）交互的数据存入AppStorage，比如持久化数据PersistentStorage和环境变量Environment。UI再通过AppStorage提供的装饰器或API接口访问这些数据。
- 框架还提供了LocalStorage，AppStorage是LocalStorage特殊的单例。LocalStorage是应用程序声明的应用状态的内存“数据库”，通常用于页面级的状态共享，通过@LocalStorageProp和@LocalStorageLink装饰器可以和UI联动。

#### 状态管理(V1)

##### 管理组件拥有的状态

###### @State装饰器：组件内状态

> 被状态变量装饰器装饰的变量称为状态变量，使普通变量具备状态属性。当状态变量改变时，会触发其直接绑定的UI组件渲染更新。
>
> 在状态变量相关装饰器中，@State是最基础的装饰器，也是大部分状态变量的数据源。

初始化规则

![0000000000011111111.20250830120308.28287587221161185999049189188074:50001231000000:2800:9775EAEC34A501751B0B3EB26EDC3685D7930339F6493ED5EDA6FE45B83DB17A.png](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyPub/011/111/111/0000000000011111111.20250830120308.28287587221161185999049189188074:50001231000000:2800:9775EAEC34A501751B0B3EB26EDC3685D7930339F6493ED5EDA6FE45B83DB17A.png)

**状态变量只能影响其直接绑定的UI组件的刷新**

```typescript
class Info {
  address: string = '杭州';

  constructor(address: string) {
    this.address = address;
  }
}

class User {
  info: Info = new Info('天津');
}

@Entry
@Component
struct Test {
  @State info: Info = new Info('上海');
  @State user: User = new User();

  aboutToAppear(): void {
    this.user.info = this.info;
  }

  build() {
    Column() {
      Text(`${this.info.address}`);
      Text(`${this.user.info.address}`);
      Button('change')
        .onClick(() => {
          this.user.info.address = '北京';
        })
    }
  }
}
```

在aboutToAppear中，info的引用被赋值给了user的成员属性info。因此，点击按钮改变info中的属性时，会触发第一个Text组件的刷新。第二个Text组件由于观测能力仅有一层，无法检测到二层属性的变化，所以不会刷新。

**使用a.b(this.object)形式调用，不会触发UI刷新**

在build方法内，当@State装饰的变量是Object类型、且通过a.b(this.object)形式调用时，b方法内传入的是this.object的原始对象，修改其属性，无法触发UI刷新。如下例中，通过静态方法Balloon.increaseVolume或者this.reduceVolume修改balloon的volume时，UI不会刷新。

状态变量观察类属性变化是通过代理捕获其变化的，当使用a.b(this.object)调用时，框架会将代理对象转换为原始对象。修改原始对象属性，无法观察，因此UI不会刷新。开发者可以使用如下方法修改：

1. 先将this.balloon赋值给临时变量。
2. 再使用临时变量完成原本的调用逻辑。

```typescript
class Balloon {
  volume: number;
  constructor(volume: number) {
    this.volume = volume;
  }

  static increaseVolume(balloon:Balloon) {
    balloon.volume += 2;
  }
}

@Entry
@Component
struct Index {
  @State balloon: Balloon = new Balloon(10);

  reduceVolume(balloon:Balloon) {
    balloon.volume -= 1;
  }

  build() {
    Column({space:8}) {
      Text(`The volume of the balloon is ${this.balloon.volume} cubic centimeters.`)
        .fontSize(30)
      Button(`increaseVolume`)
        .onClick(()=>{
          // 通过赋值给临时变量保留Proxy代理
          let balloon1 = this.balloon;
          Balloon.increaseVolume(balloon1);
        })
      Button(`reduceVolume`)
        .onClick(()=>{
          // 通过赋值给临时变量保留Proxy代理
          let balloon2 = this.balloon;
          this.reduceVolume(balloon2);
        })
    }
    .width('100%')
    .height('100%')
  }
}
```

**用注册回调的方式更改状态变量需要执行解注册**

开发者可以在aboutToAppear中注册箭头函数，以此改变组件中的状态变量。

> [!WARNING]
> 需要在aboutToDisappear中将注册的函数置空，以避免箭头函数捕获自定义组件的this实例，导致自定义组件无法被释放，从而造成内存泄漏。

```typescript
class Model {
  private callback: (() => void) | undefined = () => {};

  add(callback: () => void): void {
    this.callback = callback;
  }

  delete(): void {
    this.callback = undefined;
  }

  call(): void {
    if (this.callback) {
      this.callback();
    }
  }
}

let model: Model = new Model();

@Entry
@Component
struct Test {
  @State count: number = 10;

  aboutToAppear(): void {
    model.add(() => {
      this.count++;
    })
  }

  build() {
    Column() {
      Text(`count值: ${this.count}`)
      Button('change')
        .onClick(() => {
          model.call();
        })
    }
  }

  aboutToDisappear(): void {
    model.delete();
  }
}
```

###### @Prop装饰器：父子单向同步

> @Prop装饰的变量可以和父组件建立单向同步关系。

@Prop装饰的变量具有以下特性：

- @Prop装饰的变量允许本地修改，但修改不会同步回父组件。
- 当数据源更改时，@Prop装饰的变量都会更新，并且会覆盖本地所有更改。
-  @Prop装饰的变量是私有的，只能在组件内访问。

![0000000000011111111.20250905153532.40886385589545255636345392382156:50001231000000:2800:C44E331421B442ED2173681BA26CBC5FD0BDD1BE83CB8757EE93ECDBD7D4F695.png](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyPub/011/111/111/0000000000011111111.20250905153532.40886385589545255636345392382156:50001231000000:2800:C44E331421B442ED2173681BA26CBC5FD0BDD1BE83CB8757EE93ECDBD7D4F695.png)

允许的类型：Object、class、string、number、boolean、enum类型，以及这些类型的数组。Map， Set， Date

对于@State和@Prop的同步场景：

- 使用父组件中@State变量的值初始化子组件中的@Prop变量。当@State变量变化时，该变量值也会同步更新至@Prop变量。
- @Prop装饰的变量的修改不会影响其数据源@State装饰变量的值。
- 除了@State，数据源也可以用@Link或@Prop装饰，对@Prop的同步机制是相同的。
- 数据源和@Prop变量的类型需要相同，@Prop允许简单类型和class类型。
- 当装饰的对象是Date时，可以观察到Date整体的赋值，同时可通过调用Date的接口setFullYear, setMonth, setDate, setHours, setMinutes, setSeconds, setMilliseconds, setTime, setUTCFullYear, setUTCMonth, setUTCDate, setUTCHours, setUTCMinutes, setUTCSeconds, setUTCMilliseconds 更新Date的属性
- 当装饰的变量是Map时，可以观察到Map整体的赋值，同时可通过调用Map的接口set, clear, delete 更新Map的值
- 当装饰的变量是Set时，可以观察到Set整体的赋值，同时可通过调用Set的接口add, clear, delete 更新Set的值

**父组件@State数组项到子组件@Prop简单数据类型同步**

```typescript
@Component
struct Child {
  @Prop value: number = 0;

  build() {
    Text(`${this.value}`)
      .fontSize(50)
      .onClick(() => {
        this.value++;
      })
  }
}

@Entry
@Component
struct Index {
  @State arr: number[] = [1, 2, 3];

  build() {
    Row() {
      Column() {
        Child({ value: this.arr[0] })
        Child({ value: this.arr[1] })
        Child({ value: this.arr[2] })

        Divider().height(5)

        ForEach(this.arr,
          (item: number) => {
            Child({ value: item })
          },
          (item: number) => item.toString()
        )
        Text('replace entire arr')
          .fontSize(50)
          .onClick(() => {
            // 两个数组都包含项“3”。
            this.arr = this.arr[0] == 1 ? [3, 4, 5] : [1, 2, 3];
          })
      }
    }
  }
}
```

**@Prop嵌套场景**

在嵌套场景下，每一层都要用@Observed装饰，且每一层都要被@Prop接收，这样才能观察到嵌套场景。

```typescript
// 以下是嵌套类对象的数据结构。
@Observed
class Son {
  public title: string;

  constructor(title: string) {
    this.title = title;
  }
}

@Observed
class Father {
  public name: string;
  public son: Son;

  constructor(name: string, son: Son) {
    this.name = name;
    this.son = son;
  }
}
```

以下组件层次结构展示了@Prop嵌套场景的数据结构。

```typescript
@Entry
@Component
struct Person {
  @State person: Father = new Father('Hello', new Son('world'));

  build() {
    Column() {
      Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center }) {
        Button('change Father name')
          .width(312)
          .height(40)
          .margin(12)
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.person.name = 'Hi';
          })
        Button('change Son title')
          .width(312)
          .height(40)
          .margin(12)
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.person.son.title = 'ArkUI';
          })
        Text(this.person.name)
          .fontSize(16)
          .margin(12)
          .width(312)
          .height(40)
          .backgroundColor('#ededed')
          .borderRadius(20)
          .textAlign(TextAlign.Center)
          .fontColor('#e6000000')
          .onClick(() => {
            this.person.name = 'Bye';
          })
        Text(this.person.son.title)
          .fontSize(16)
          .margin(12)
          .width(312)
          .height(40)
          .backgroundColor('#ededed')
          .borderRadius(20)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.person.son.title = 'openHarmony';
          })
        Child({ child: this.person.son })
      }
    }
  }
}


@Component
struct Child {
  @Prop child: Son = new Son('');

  build() {
    Column() {
      Text(this.child.title)
        .fontSize(16)
        .margin(12)
        .width(312)
        .height(40)
        .backgroundColor('#ededed')
        .borderRadius(20)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.child.title = 'Bye Bye';
        })
    }
  }
}
```

**使用a.b(this.object)形式调用，不会触发UI刷新**

在build方法内，当@Prop装饰的变量是Object类型、且通过a.b(this.object)形式调用时，b方法内传入的是this.object的原始对象，修改其属性，无法触发UI刷新。如下例中，通过静态方法Score.changeScore1或者this.changeScore2修改自定义组件Child中的this.score.value时，UI不会刷新。

```typescript
class Score {
  value: number;
  constructor(value: number) {
    this.value = value;
  }

  static changeScore1(param1:Score) {
    param1.value += 1;
  }
}

@Entry
@Component
struct Parent {
  @State score: Score = new Score(1);

  build() {
    Column({space:8}) {
      Text(`The value in Parent is ${this.score.value}.`)
        .fontSize(30)
        .fontColor(Color.Red)
      Child({ score: this.score })
    }
    .width('100%')
    .height('100%')
  }
}

@Component
struct Child {
  @Prop score: Score;

  changeScore2(param2:Score) {
    param2.value += 2;
  }

  build() {
    Column({space:8}) {
      Text(`The value in Child is ${this.score.value}.`)
        .fontSize(30)
      Button(`changeScore1`)
        .onClick(()=>{
          // 通过静态方法调用，无法触发UI刷新
          Score.changeScore1(this.score);
        })
      Button(`changeScore2`)
        .onClick(()=>{
          // 使用this通过自定义组件内部方法调用，无法触发UI刷新
          this.changeScore2(this.score);
        })
    }
  }
}
```

正例

```typescript
class Score {
  value: number;
  constructor(value: number) {
    this.value = value;
  }

  static changeScore1(score:Score) {
    score.value += 1;
  }
}

@Entry
@Component
struct Parent {
  @State score: Score = new Score(1);

  build() {
    Column({space:8}) {
      Text(`The value in Parent is ${this.score.value}.`)
        .fontSize(30)
        .fontColor(Color.Red)
      Child({ score: this.score })
    }
    .width('100%')
    .height('100%')
  }
}

@Component
struct Child {
  @Prop score: Score;

  changeScore2(score:Score) {
    score.value += 2;
  }

  build() {
    Column({space:8}) {
      Text(`The value in Child is ${this.score.value}.`)
        .fontSize(30)
      Button(`changeScore1`)
        .onClick(()=>{
          // 通过赋值添加 Proxy 代理
          let score1 = this.score;
          Score.changeScore1(score1);
        })
      Button(`changeScore2`)
        .onClick(()=>{
          // 通过赋值添加 Proxy 代理
          let score2 = this.score;
          this.changeScore2(score2);
        })
    }
  }
}
```

###### @Link装饰器：父子双向同步

> **@Link装饰的变量与其父组件中的数据源共享相同的值。**

允许的类型：Object、class、string、number、boolean、enum类型，以及这些类型的数组。Map, Set, Date

> [!Warning]
>
> 1. @Link的数据源必须是**装饰器装饰的状态变量**
> 2. @Link装饰器不建议在@Entry装饰的自定义组件中使用，否则编译时会抛出警告；若该自定义组件作为页面根节点使用，则会抛出运行时错误。
> 3. @Link装饰的变量禁止本地初始化，否则编译期会报错。
> 4. @Link装饰的变量的类型要和数据源类型保持一致，否则框架会抛出运行时错误。
> 5. @Link装饰的变量仅能被状态变量初始化，不能使用常规变量初始化，否则编译期会给出告警，并在运行时崩溃。
> 6. @Link不支持装饰Function类型的变量，框架会抛出运行时错误。

**使用双向同步机制更改本地其他变量**

```typescript
//以下示例中，在@Link的@Watch里面修改了一个@State装饰的变量memberMessage，实现父子组件间的变量同步。但是@State装饰的变量memberMessage在本地修改不会影响到父组件中的变量改变。
@Entry
@Component
struct Parent {
  @State sourceNumber: number = 0;

  build() {
    Column() {
      Text(`父组件的sourceNumber：` + this.sourceNumber)
      Child({ sourceNumber: this.sourceNumber })
      Button('父组件更改sourceNumber')
        .onClick(() => {
          this.sourceNumber++;
        })
    }
    .width('100%')
    .height('100%')
  }
}

@Component
struct Child {
  @State memberMessage: string = 'Hello World';
  @Link @Watch('onSourceChange') sourceNumber: number;

  onSourceChange() {
    this.memberMessage = this.sourceNumber.toString();
  }

  build() {
    Column() {
      Text(this.memberMessage)
      Text(`子组件的sourceNumber：` + this.sourceNumber.toString())
      Button('子组件更改memberMessage')
        .onClick(() => {
          this.memberMessage = 'Hello memberMessage';
        })
    }
  }
}
```

**Link支持联合类型实例**

@Link支持联合类型、undefined和null

```typescript
//name类型为string | undefined。点击父组件Index中的按钮可以改变name的属性或类型，Child组件也会相应刷新。
@Component
struct Child {
  @Link name: string | undefined;

  build() {
    Column() {

      Button('Child change name to Bob')
        .onClick(() => {
          this.name = 'Bob';
        })

      Button('Child change name to undefined')
        .onClick(() => {
          this.name = undefined;
        })

    }.width('100%')
  }
}

@Entry
@Component
struct Index {
  @State name: string | undefined = 'mary';

  build() {
    Column() {
      Text(`The name is  ${this.name}`).fontSize(30)

      Child({ name: this.name })

      Button('Parents change name to Peter')
        .onClick(() => {
          this.name = 'Peter';
        })

      Button('Parents change name to undefined')
        .onClick(() => {
          this.name = undefined;
        })
    }
  }
}
```

**使用a.b(this.object)形式调用，不会触发UI刷新**(同@Prop)

###### @Provide装饰器和@Consume装饰器：与后代组件双向同步

> @Provide和@Consume，应用于与后代组件的双向数据同步、状态数据在多个层级之间传递的场景。不同于上文提到的父子组件之间通过命名参数机制传递，@Provide和@Consume摆脱参数传递机制的束缚，实现跨层级传递。
>
> 其中@Provide装饰的变量是在祖先组件中，可以理解为被“提供”给后代的状态变量。@Consume装饰的变量是在后代组件中，去“消费（绑定）”祖先组件提供的变量。
>
> @Provide/@Consume是跨组件层级的双向同步

@Provide/@Consume装饰的状态变量有以下特性：

- @Provide装饰的状态变量自动对其所有后代组件可用，开发者不需要多次在组件之间传递变量。
- 后代通过使用@Consume去获取@Provide提供的变量，建立在@Provide和@Consume之间的双向数据同步，与@State/@Link不同的是，前者可以更便捷的在多层级父子组件之间传递。
- @Provide和@Consume通过变量名或者变量别名绑定，需要类型相同，否则会发生类型隐式转换，从而导致应用行为异常。

```typescript
// 通过相同的变量名绑定
@Provide age: number = 0;
@Consume age: number;

// 通过相同的变量别名绑定
@Provide('a') id: number = 0;
@Consume('a') age: number;

// 通过Provide的变量别名和Consume的变量名相同绑定
@Provide('a') id: number = 0;
@Consume a: number;

// 通过Provide的变量名和Consume的变量别名绑定
@Provide id: number = 0;
@Consume('id') a: number;

//当@Provide指定变量别名时，会同时保存变量名与变量别名，@Consume在查找时，会优先以变量别名作为查找值去匹配，如果没有别名则用变量名作为查找值，只要@Consume提供的查找值与@Provide保存的变量名或别名中任意一项一致，即可成功建立绑定关系。
```

允许的类型：Object、class、string、number、boolean、enum类型，以及这些类型的数组。Map, Set, Date

> [!Warning]
>
> 1. @Provide/@Consume的参数key必须为string类型，否则编译期会报错。
>
>    ```typescript
>    // 错误写法，编译报错
>    let change: number = 10;
>    @Provide(change) message: string = 'Hello';
>    
>    // 正确写法
>    let change: string = 'change';
>    @Provide(change) message: string = 'Hello';
>    ```
>
> 2. @Consume装饰的变量不能在构造参数中传入初始化，否则编译期会报错。@Consume仅能通过key来匹配对应的@Provide变量或者从API version 20开始设置默认值进行初始化。
>
> 3. @Provide的key重复定义时，框架会抛出运行时错误，提醒开发者重复定义key，
>
> 4. @Provide与@Consume不支持装饰Function类型的变量，框架会抛出运行时错误。
>
> 5. 在非BuilderNode场景中，建议配对的@Provide/@Consume类型一致。虽然在运行时不会有强校验，但在@Consume装饰的变量初始化时，会隐式转换成@Provide装饰变量的类型。

###### @Observed装饰器和@ObjectLink

> 实现对嵌套数据结构中深层属性变化的观察

> [!Warning]
>
> 1. @ObjectLink的属性可以被改变，但不允许整体赋值，即@ObjectLink装饰的变量是只读的。
>
>    ```typescript
>    // 允许@ObjectLink装饰的数据属性赋值
>    this.objLink.a= ...
>    // 不允许@ObjectLink装饰的数据自身赋值
>    this.objLink= ...
>    ```
>
> 2. @Observed装饰的类，如果其属性为非简单类型，比如class、Object或者数组，那么这些属性也需要被@Observed装饰，否则将观察不到这些属性的变化。
>
> 3. @ObjectLink：@ObjectLink只能接收被@Observed装饰class的实例，推荐设计单独的自定义组件来渲染每一个数组或对象。
>
> 4. @ObjectLink装饰器不能在@Entry装饰的自定义组件中使用。
>
> 5. @ObjectLink装饰的类型必须是复杂类型，否则会有编译期报错。
>
>    ```typescript
>    @Observed
>    class Info {
>      count: number;
>                            
>      constructor(count: number) {
>        this.count = count;
>      }
>    }
>                            
>    class Test {
>      msg: number;
>                            
>      constructor(msg: number) {
>        this.msg = msg;
>      }
>    }
>                            
>    // 错误写法，count未指定类型，编译报错
>    @ObjectLink count;
>    // 错误写法，Test未被@Observed装饰，编译报错
>    @ObjectLink test: Test;
>                            
>    // 正确写法
>    @ObjectLink count: Info;
>    ```
>

##### 管理应用拥有的状态管理应用拥有的状态

###### LocalStorage：页面级UI状态存储

LocalStorage根据与@Component装饰的组件的同步类型不同，提供了两个装饰器：

- @LocalStorageProp：@LocalStorageProp装饰的变量与LocalStorage中给定属性建立单向同步关系。
  ![img](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyPub/011/111/111/0000000000011111111.20250922204451.21920139026752041556876031936113:50001231000000:2800:40502FFCDFCE7C1237C08852D7499FC52BE102A1CC974EE4E7C48A97D1D6ABBD.png)
- @LocalStorageLink：@LocalStorageLink装饰的变量与LocalStorage中给定属性建立双向同步关系。
  ![img](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyPub/011/111/111/0000000000011111111.20250922204451.32056782783863968129497941309382:50001231000000:2800:F7941CE86504FA52A4C4D876FF8531FBEC0DC36581F27C19BDCD1274E8069576.png)

> [!Warning]
>
> 1. @LocalStorageProp/@LocalStorageLink的参数必须为string类型，否则编译期会报错。
>
>    ```typescript
>    let storage = new LocalStorage();
>    storage.setOrCreate('PropA', 48);
>    
>    // 错误写法，编译报错
>    @LocalStorageProp() localStorageProp: number = 1;
>    @LocalStorageLink() localStorageLink: number = 2;
>    
>    // 正确写法
>    @LocalStorageProp('PropA') localStorageProp: number = 1;
>    @LocalStorageLink('PropA') localStorageLink: number = 2;
>    ```
>
> 2. @LocalStorageProp与@LocalStorageLink不支持装饰Function类型的变量，框架会抛出运行时错误。
>
> 3. LocalStorage创建后，命名属性的类型不可更改。后续调用Set时必须使用相同类型的值。

###### AppStorage：应用全局的UI状态存储

1. @StorageProp(key)装饰的数值发生变化，不会同步写回AppStorage对应的属性；变化会触发自定义组件重新渲染，并且该变动仅作用于当前组件的私有成员变量，其他绑定该key的数据不会同步改变。
2. 当AppStorage中对应key的属性发生改变时，所有@StorageProp(key)装饰的变量都会同步更新，本地的修改将被覆盖。

![img](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyPub/011/111/111/0000000000011111111.20250922204453.77041490241472246078597498538851:50001231000000:2800:C895A67CBA810CF93C14B29F0126E02E29DE56F28C1E290AEBE00B658DDDD88B.png)

> [!Warning]
>
> 1. @StorageProp/@StorageLink的参数必须为string类型，否则编译期会报错。
> 2. @StorageProp与@StorageLink不支持装饰Function类型的变量，框架会抛出运行时错误。
> 3. AppStorage与PersistentStorage以及Environment配合使用时，需要注意以下几点：
>    - 在AppStorage中创建属性后，调用PersistentStorage.persistProp接口时，会使用AppStorage中已存在的值，并覆盖PersistentStorage中的同名属性。因此，建议使用相反的调用顺序。反例可见在PersistentStorage之前访问AppStorage中的属性。
>    - 如果在AppStorage中已创建属性，再调用Environment.envProp创建同名属性，会调用失败。因为AppStorage已有同名属性，Environment环境变量不会再写入AppStorage中，所以建议不要在AppStorage中使用Environment预置环境变量名。
> 4. 状态装饰器装饰的变量，改变会引起UI的渲染更新。如果改变的变量仅用于消息传递，不用于UI更新，推荐使用emitter方式。具体示例可见不建议借助@StorageLink的双向同步机制实现事件通知。
> 5. AppStorage同一进程内共享，UIAbility和UIExtensionAbility是两个进程，所以在UIExtensionAbility中不共享主进程的AppStorage。

###### PersistentStorage：持久化存储UI状态

PersistentStorage将选定的AppStorage属性保留在设备磁盘上。

###### Environment：设备环境查询

Environment提供了读取系统环境变量并将其值写入AppStorage的功能。开发者需要通过AppStorage获取环境变量的值

##### 其他状态管理

###### @Watch装饰器：状态变量更改通知

@Watch应用于对状态变量的监听。如果开发者需要关注某个状态变量的值是否改变，可以使用@Watch为状态变量设置回调函数。

@Watch提供了状态变量的监听能力，@Watch仅能监听到可以观察到的变化。

- 建议开发者避免无限循环。循环可能是因为在@Watch的回调方法里直接或者间接地修改了同一个状态变量引起的。为了避免循环的产生，建议不要在@Watch的回调方法里修改当前装饰的状态变量；
- 开发者应关注性能，属性值更新函数会延迟组件的重新渲染（具体请见上面的行为表现），因此，回调函数应仅执行快速运算；
- 不建议在@Watch函数中调用async await，因为@Watch设计的用途是为了快速的计算，异步行为可能会导致重新渲染速度的性能问题。
- @Watch参数为必选，且参数类型必须是string，否则编译期会报错。不建议开发者传入undefined，传入后编译不会报错，相当于传入“undefined”。

```typescript
// 错误写法，编译报错
@State @Watch() num: number = 10;
@State @Watch(change) num: number = 10;

// 正确写法
@State @Watch('change') num: number = 10;
change() {
  console.info(`xxx`);
}
```

###### $$语法：系统组件双向同步

$$运算符为系统组件提供TS变量的引用，使得TS变量和系统组件的内部状态保持同步。

###### @Track装饰器：class对象属性级更新

@Track应用于class对象的属性级更新。@Track装饰的属性变化时，只会触发该属性关联的UI更新。

###### 自定义组件冻结功能

**略**

##### MVVM模式

- View：用户界面层。负责用户界面展示并与用户交互，不包含任何业务逻辑。它通过绑定ViewModel层提供的数据实现动态更新。

- Model：数据访问层。以数据为中心，不直接与用户界面交互。负责数据结构定义，数据管理（获取、存储、更新等），以及业务逻辑处理。

- ViewModel：表示逻辑层。作为连接Model和View的桥梁，通常一个View对应一个ViewModel。View和ViewModel有两种通信方式：

  1.方法调用：View通过事件监听用户行为，在回调里面触发ViewModel层的方法。例如当View监听到用户Button点击行为，调用ViewModel对应的方法，处理用户操作。

  2.双向绑定：View绑定ViewModel的数据，实现双向同步。



![img](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyPub/011/111/111/0000000000011111111.20250922204421.80111038084915544170487908222959:50001231000000:2800:8121F84A5C7CEDF135E9EC57B41EE0187D7904FC5EB184FEC2508F162AB04A2B.png)

#### 状态管理(V2)

##### V2所属装饰器

###### @ObservedV2装饰器和@Trace装饰器：类属性变化观测

- @ObservedV2装饰器与@Trace装饰器需要配合使用，单独使用@ObservedV2装饰器或@Trace装饰器没有任何作用。
- 被@Trace装饰器装饰的属性property变化时，仅会通知property关联的组件进行刷新。
- 在嵌套类中，嵌套类中的属性property被@Trace装饰且嵌套类被@ObservedV2装饰时，才具有触发UI刷新的能力。
- 在继承类中，父类或子类中的属性property被@Trace装饰且该property所在类被@ObservedV2装饰时，才具有触发UI刷新的能力。
- 未被@Trace装饰的属性用在UI中无法感知到变化，也无法触发UI刷新。
- @ObservedV2的类实例目前不支持使用JSON.stringify进行序列化。
- 使用@ObservedV2与@Trace装饰器的类，需通过new操作符实例化后，才具备被观测变化的能力。

###### @ComponentV2装饰器：自定义组件

- 在@ComponentV2装饰的自定义组件中，开发者仅可以使用全新的状态变量装饰器，包括@Local、@Param、@Once、@Event、@Provider、@Consumer等。
- @ComponentV2装饰的自定义组件暂不支持LocalStorage等现有自定义组件的能力。
- 无法同时使用@ComponentV2与@Component装饰同一个struct结构。
- @ComponentV2支持一个可选的boolean类型参数freezeWhenInactive，来实现组件冻结功能。

###### @Local装饰器：组件内部状态

- 被@Local装饰的变量无法从外部初始化，因此必须在组件内部进行初始化。
- 当被@Local装饰的变量变化时，会刷新使用该变量的组件。
- @Local支持观测number、boolean、string、Object、class等基本类型以及Array,Set,Map,Date等内嵌类型。
- @Local的观测能力仅限于被装饰的变量本身。当装饰简单类型时，能够观测到对变量的赋值；当装饰对象类型时，仅能观测到对对象整体的赋值；当装饰数组类型时，能观测到数组整体以及数组元素项的变化；当装饰Array、Set、Map、Date等内嵌类型时，可以观测到通过API调用带来的变化。
- @Local支持null、undefined以及联合类型。

###### @Param：组件外部输入

@Param不仅可以接受组件外部输入，还可以接受@Local的同步变化。

- @Param装饰的变量支持本地初始化，但不允许在组件内部直接修改。
- 被@Param装饰的变量能够在初始化自定义组件时从外部传入，当数据源也是状态变量时，数据源的修改会同步给@Param。
- @Param可以接受任意类型的数据源，包括普通变量、状态变量、常量、函数返回值等。
- @Param装饰的变量变化时，会刷新该变量关联的组件。
- @Param支持对基本类型（如number、boolean、string、Object、class）、内嵌类型（如Array,Set,Map,Date），以及null、undefined和联合类型进行观测。
- 对于复杂类型如类对象，@Param会接受数据源的引用。在组件内可以修改类对象中的属性，该修改会同步到数据源。
- @Param的观测能力仅限于被装饰的变量本身

###### @Once：初始化同步一次

@Once装饰器在变量初始化时接受外部传入值进行初始化，后续数据源更改不会同步给子组件：

- @Once必须搭配@Param使用，单独使用或搭配其他装饰器使用都是不允许的。
  @Once仅在[@ComponentV2](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-new-componentv2)装饰的自定义组件中与@Param搭配使用。

  ```typescript
  @ComponentV2
  struct MyComponent {
    @Param @Once onceParam: string = 'onceParam'; // 正确用法
    @Once onceStr: string = 'Once'; // 错误用法，@Once无法单独使用
    @Local @Once onceLocal: string = 'onceLocal'; // 错误用法，@Once不能与@Local一起使用
  }
  @Component
  struct Index {
    @Once @Param onceParam: string = 'onceParam'; // 错误用法
  }
  ```

- @Once不影响@Param的观测能力，仅针对数据源的变化做拦截。
- @Once与@Param装饰变量的先后顺序不影响使用功能。
- @Once与@Param搭配使用时，可以在本地修改@Param变量的值。

###### @Event装饰器：规范组件输出

@Event主要配合@Param实现数据的双向同步。

由于@Param装饰的变量在本地无法更改，使用@Event装饰器装饰回调方法并调用，可以实现更新数据源的变量，再通过[@Local](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-new-local)的同步机制，将修改同步回@Param装饰的变量，以此达到主动更新@Param装饰变量的效果。

@Event用于装饰组件对外输出的方法：

- @Event装饰的回调方法中参数以及返回值由开发者决定。

- @Event装饰非回调类型的变量不会生效。当@Event没有初始化时，会自动生成一个空的函数作为默认回调。

  ```typescript
  @ComponentV2
  struct Index {
    @Event changeFactory: () => void = () => {}; //正确用法
    @Event message: string = 'abcd'; // 错误用法，装饰非函数类型变量，@Event无作用
  }
  @Component
  struct Index {
    @Event changeFactory: () => void = () => {}; // 错误用法，编译时报错
  }
  ```

- 当@Event未被外部初始化，但本地有默认值时，会使用本地默认的函数进行处理。

@Param标志着组件的输入，表明该变量受父组件影响，而@Event标志着组件的输出，可以通过该方法影响父组件。使用@Event装饰回调方法是一种规范，表明该回调作为自定义组件的输出。父组件需要判断是否提供对应方法用于子组件更改@Param变量的数据源。

###### @Provider装饰器和@Consumer装饰器：跨组件层级双向同步

@Provider和@Consumer用于跨组件层级数据双向同步，可以使得开发者不用拘泥于组件层级。

@Provider，即数据提供方，其所有的子组件都可以通过@Consumer绑定相同的key来获取@Provider提供的数据。

@Consumer，即数据消费方，可以通过绑定同样的key获取其最近父节点的@Provider的数据，当查找不到@Provider的数据时，使用本地默认值。图示如下。

![img](https://alliance-communityfile-drcn.dbankcdn.com/FileServer/getFile/cmtyPub/011/111/111/0000000000011111111.20250922204459.37927724815629641544925929700646:50001231000000:2800:614FA5FB3DA54F1B695D59C26217DC5E120B0B60928AE74542E54096C0683821.png)

@Provider和@Consumer装饰的数据类型需要一致。

开发者在使用@Provider和@Consumer时要注意：

- @Provider和@Consumer强依赖自定义组件层级，@Consumer会因为所在组件的父组件不同，而被初始化为不同的值。
- @Provider和@Consumer相当于把组件粘合在一起了，从组件独立角度考虑，应减少使用@Provider和@Consumer。

```typescript
@ComponentV2
struct Parent {
  // 未定义aliasName, 使用属性名'str'作为aliasName
  @Provider() str: string = 'hello';
}

@ComponentV2
struct Child {
  // 定义aliasName为'str'，使用aliasName去寻找
  // 能够在Parent组件上找到, 使用@Provider的值'hello'
  @Consumer('str') str: string = 'world';
}
```

###### @Monitor装饰器：状态变量修改监听

@Monitor装饰器用于监听状态变量修改，使得状态变量具有深度监听的能力：

- @Monitor装饰器支持在@ComponentV2装饰的自定义组件中使用，未被状态变量装饰器@Local,@Param,@Provider，@Consumer装饰的变量无法被@Monitor监听到变化。
- @Monitor装饰器支持在类中与@ObservedV2、@Trace配合使用，不允许在未被@ObservedV2装饰的类中使用@Monitor装饰器。未被@Trace装饰的属性无法被@Monitor监听到变化。
- 当观测的属性变化时，@Monitor装饰器定义的回调方法将被调用。判断属性是否变化使用的是严格相等（===），当严格相等判断的结果是false（即不相等）的情况下，就会触发@Monitor的回调。当在一次事件中多次改变同一个属性时，将会使用初始值和最终值进行比较以判断是否变化。
- 单个@Monitor装饰器能够同时监听多个属性的变化，当这些属性在一次事件中共同变化时，只会触发一次@Monitor的回调方法。
- @Monitor装饰器具有深度监听的能力，能够监听嵌套类、多维数组、对象数组中指定项的变化。对于嵌套类、对象数组中成员属性变化的监听要求该类被@ObservedV2装饰且该属性被@Trace装饰。
- 当@Monitor监听整个数组时，更改数组的某一项不会被监听到。无法监听内置类型（Array、Map、Date、Set）的API调用引起的变化。
- 在继承类场景中，可以在父子组件中对同一个属性分别定义@Monitor进行监听，当属性变化时，父子组件中定义的@Monitor回调均会被调用。
- 和@Watch装饰器类似，开发者需要自己定义回调函数，区别在于@Watch装饰器将函数名作为参数，而@Monitor直接装饰回调函数。

###### @Computed装饰器：计算属性

当开发者使用相同的计算逻辑重复绑定在UI上时，为了防止重复计算，

```typescript
@Computed
get sum() {
  return this.count1 + this.count2 + this.count3;
}
Text(`${this.count1 + this.count2 + this.count3}`) // 计算this.count1 + this.count2 + this.count3
Text(`${this.count1 + this.count2 + this.count3}`) // 重复计算this.count1 + this.count2 + this.count3
Text(`${this.sum}`) // 读取@Computed sum的缓存值，节省上述重复计算
Text(`${this.sum}`) // 读取@Computed sum的缓存值，节省上述重复计算
```

对于简单计算，不建议使用计算属性，因为计算属性本身也有开销。对于复杂的计算，@Computed能带来性能收益。

只有被观察到的变化才会触发@Computed函数重新计算。

@Computed可以初始化@Param(对象参数)。

###### @Type装饰器：标记类属性的类型

实现序列化类时不丢失属性的复杂类型

@Type的目的是标记类属性，配合PersistenceV2使用

```typescript
import { PersistenceV2, Type } from '@kit.ArkUI';

@ObservedV2
class SampleChild {
  @Trace childNumber: number = 1;
}

@ObservedV2
class Sample {
  // 对于复杂对象需要@Type修饰，确保反序列化成功，去掉@Type会反序列化值失败。
  @Type(SampleChild)
  // 对于没有初值的类属性，经过@Type修饰后，需要手动保存，否则持久化失败。
  // 无法使用@Type修饰的类属性，必须要有初值才能持久化。
  @Trace sampleChild?: SampleChild = undefined;
}

@Entry
@ComponentV2
struct TestCase {
  @Local sample: Sample = PersistenceV2.connect(Sample, () => new Sample)!;

  build() {
    Column() {
      Text('childNumber value:' + this.sample.sampleChild?.childNumber)
        .onClick(() => {
          this.sample.sampleChild = new SampleChild();
          this.sample.sampleChild.childNumber = 2;
          PersistenceV2.save(Sample);
        })
        .fontSize(30)
    }
  }
}
```

###### @ReusableV2装饰器：组件复用

为了降低反复创建销毁自定义组件带来的性能开销，开发者可以使用@ReusableV2装饰@ComponentV2装饰的自定义组件，达成组件复用的效果。

> [!Warning]
>
> - @ReusableV2仅能装饰V2的自定义组件，即@ComponentV2装饰的自定义组件。并且仅能将@ReusableV2装饰的自定义组件作为V2自定义组件的子组件使用。
> - @ReusableV2同样提供了aboutToRecycle和aboutToReuse的生命周期，在组件被回收时调用aboutToRecycle，在组件被复用时调用aboutToReuse，但与@Reusable不同的是，aboutToReuse没有入参。
> - 在回收阶段，会递归地调用所有子组件的aboutToRecycle回调（即使子组件未被标记可复用）；在复用阶段，会递归地调用所有子组件的aboutToReuse回调（即使子组件未被标记可复用）。
> - @ReusableV2装饰的自定义组件会在被回收期间保持冻结状态，即无法触发UI刷新、无法触发@Monitor回调，与freezeWhenInactive标记位不同的是，在解除冻结状态后，不会触发延后的刷新。
> - @ReusableV2装饰的自定义组件会在复用时自动重置组件内状态变量的值、重新计算组件内@Computed以及与之相关的@Monitor。不建议开发者在aboutToRecycle中更改组件内状态变量，

V2的复用组件当前不支持直接用于[Repeat](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-rendering-control-repeat)的template中，但是可以用在template中的V2自定义组件中。

```typescript
@Entry
@ComponentV2
struct Index {
  @Local arr: number[] = [1, 2, 3, 4, 5];
  build() {
    Column() {
      List() {
        Repeat(this.arr)
          .each(() => {})
          .virtualScroll()
          .templateId(() => 'a')
          .template('a', (ri) => {
            ListItem() {
              Column() {
                ReusableV2Component({ val: ri.item}) // 暂不支持，编译期报错
                ReusableV2Builder(ri.item) // 暂不支持，运行时报错
                NormalV2Component({ val: ri.item}) // 支持普通V2自定义组件下面包含V2复用组件              
              }
            }
          })
      }
    }
  }
}
@ComponentV2
struct NormalV2Component {
  @Require @Param val: number;
  build() {
    ReusableV2Component({ val: this.val })
  }
}
@Builder
function ReusableV2Builder(param: number) {
  ReusableV2Component({ val: param })
}
@ReusableV2
@ComponentV2
struct ReusableV2Component {
  @Require @Param val: number;
  build() {
    Column() {
      Text(`val: ${this.val}`)
    } 
  }
}
```

##### 其他状态

###### AppStorageV2: 应用全局UI状态存储

**使用限制**

1、只支持class类型。

2、需要配合UI使用（UI线程），不能在其他线程使用，如不支持@Sendable。

3、不支持collections.Set、collections.Map等类型。

4、不支持非built-in类型，如[PixelMap](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-image-pixelmap)、NativePointer、[ArrayList](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-arraylist)等Native类型。

5、不支持存储基本类型，如string、number、boolean等。注意：不支持存储基本类型意味着connect接口传入的类型不能是基本类型，但connect传入的class中可以包含基本类型。

**使用场景**

```typescript
import { AppStorageV2 } from '@kit.ArkUI';

@ObservedV2
class Message {
  @Trace userID: number;
  userName: string;

  constructor(userID?: number, userName?: string) {
    this.userID = userID ?? 1;
    this.userName = userName ?? 'Jack';
  }
}

@Entry
@ComponentV2
struct Index {
  // 使用connect在AppStorageV2中创建一个key为Message的对象
  // 修改connect的返回值即可同步回AppStorageV2
  @Local message: Message = AppStorageV2.connect<Message>(Message, () => new Message())!;

  build() {
    Column() {
      // 修改@Trace装饰的类属性，UI能同步刷新
      Button(`Index userID: ${this.message.userID}`)
        .onClick(() => {
          this.message.userID += 1;
        })
      // 修改非@Trace装饰的类属性，UI不会同步刷新，但修改的类属性已同步回AppStorageV2
      Button(`Index userName: ${this.message.userName}`)
        .onClick(() => {
          this.message.userName += 'suf';
        })
      // remove key Message, 会从AppStorageV2中删除key为Message的对象
      // remove之后，修改父组件的userId，子组件能同步变化，因为remove只是从AppStorageV2删除，不会影响组件中已存在的数据
      Button('remove key: Message')
        .onClick(() => {
          AppStorageV2.remove<Message>(Message);
        })
      // connect key Message, 会从AppStorageV2中添加key为Message的对象
      // remove之后，重新添加，修改父子组件的userID，可以发现数据已经不同步，子组件重新connect之后，数据一致
      Button('connect key: Message')
        .onClick(() => {
          this.message = AppStorageV2.connect<Message>(Message, () => new Message(5, 'Rose'))!;
        })
      Divider()
      Child()
    }
    .width('100%')
    .height('100%')
  }
}

@ComponentV2
struct Child {
  // 使用connect在AppStorageV2中取出一个key为Message的对象，已在父组件中创建
  @Local message: Message = AppStorageV2.connect<Message>(Message, () => new Message())!;
  @Local name: string = this.message.userName;

  build() {
    Column() {
      // 修改@Trace装饰的类属性，UI同步刷新，父组件能感知该变化
      Button(`Child userID: ${this.message.userID}`)
        .onClick(() => {
          this.message.userID += 5;
        })
      // 修改父组件中的userName属性，点击name可以同步父组件的类属性修改
      Button(`Child name: ${this.name}`)
        .onClick(() => {
          this.name = this.message.userName;
        })
      // remove key Message, 会从AppStorageV2中删除key为Message的对象
      Button('remove key: Message')
        .onClick(() => {
          AppStorageV2.remove<Message>(Message);
        })
      // connect key Message, 会从AppStorageV2中添加key为Message的对象
      Button('connect key: Message')
        .onClick(() => {
          this.message = AppStorageV2.connect<Message>(Message, () => new Message(10, 'Lucy'))!;
        })
    }
    .width('100%')
    .height('100%')
  }
}
```

###### PersistenceV2: 持久化存储UI状态

PersistenceV2是在应用UI启动时会被创建的单例。它的目的是提供应用状态数据的中心存储，这些状态数据在应用级别都是可访问的。数据通过唯一的键值字符串访问。不同于AppStorageV2，PersistenceV2还将最新数据存储在设备磁盘上（持久化）

**使用场景**

```typescript
// EntryAbility.ets
// 以下为代码片段，需要开发者自己在EntryAbility.ets中补全
import { PersistenceV2 } from '@kit.ArkUI';

// 在EntryAbility外部定义class
@ObservedV2
class Storage {
  @Trace isPersist: boolean = false;
}

// 在onWindowStageCreate的loadContent回调中调用PersistenceV2
onWindowStageCreate(windowStage: window.WindowStage): void {
  windowStage.loadContent('pages/Index', (err) => {
    if (err.code) {
      return;
    }
    PersistenceV2.connect(Storage, () => new Storage());
  });
}
```

###### !!语法：双向绑定

在状态管理V1中，推荐使用[$$](######$$语法：系统组件双向同步)实现系统组件的双向绑定。

在状态管理V2中，推荐使用!!语法糖统一处理双向绑定。

------

## 渲染控制

### if/else：条件渲染

```typescript
@Entry
@Component
struct MyComponent {
  @State count: number = 0;

  build() {
    Column() {
      Text(`count=${this.count}`)

      if (this.count > 0) {
        Text(`count is positive`)
          .fontColor(Color.Green)
      }

      Button('increase count')
        .onClick(() => {
          this.count++;
        })

      Button('decrease count')
        .onClick(() => {
          this.count--;
        })
    }
  }
}
```

### ForEach：循环渲染

ForEach接口基于数组循环渲染，需要与容器组件配合使用，且接口返回的组件应当是允许包含在ForEach父容器组件中的子组件。例如，ListItem组件要求ForEach的父容器组件必须为List组件。

#### 拖拽排序

在List组件下使用ForEach，并设置onMove事件，每次迭代生成一个ListItem时，可以使能拖拽排序。拖拽排序离手后，如果数据位置发生变化，将触发onMove事件，上报数据移动原始索引号和目标索引号。在onMove事件中，需要根据上报的起始索引号和目标索引号修改数据源。数据源修改前后，要保持每个数据的键值不变，只是顺序发生变化，才能保证落位动画正常执行。

```typescript
@Entry
@Component
struct ForEachSort {
  @State arr: Array<string> = [];

  build() {
    Column() {
      // 点击此按钮会触发ForEach重新渲染
      Button('Add one item')
        .onClick(() => {
          this.arr.push('10');
        })
        .width(300)
        .margin(10)

      List() {
        ForEach(this.arr, (item: string) => {
          ListItem() {
            Text(item.toString())
              .fontSize(16)
              .textAlign(TextAlign.Center)
              .size({ height: 100, width: '100%' })
          }.margin(10)
          .borderRadius(10)
          .backgroundColor('#FFFFFFFF')
        }, (item: string) => item)
          .onMove((from: number, to: number) => {
            // 以下两行代码是为了确保拖拽后屏幕上组件的顺序与数组arr中每一项的顺序保持一致。
            // 若注释以下两行，第一步拖拽排序，第二步在arr末尾插入一项，触发ForEach渲染，此时屏上组件的顺序会跟数组arr中每一项的顺序一致，而不是维持第一步拖拽后的顺序，意味着拖拽排序在ForEach渲染后失效了。
            let tmp = this.arr.splice(from, 1);
            this.arr.splice(to, 0, tmp[0]);
          })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFDCDCDC')
    }
  }

  aboutToAppear(): void {
    for (let i = 0; i < 10; i++) {
      this.arr.push(i.toString());
    }
  }
}
```

#### 渲染性能降低

```typescript
@Entry
@Component
struct Parent {
  @State simpleList: Array<string> = ['one', 'two', 'three'];

  build() {
    Column() {
      Button() {
        Text('在第1项后插入新项').fontSize(30)
      }
      .onClick(() => {
        this.simpleList.splice(1, 0, 'new item');
        console.info(`[onClick]: simpleList is [${this.simpleList.join(', ')}]`);
      })

      ForEach(this.simpleList, (item: string) => {
        ChildItem({ item: item })
      })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
    .backgroundColor(0xF1F3F5)
  }
}

@Component
struct ChildItem {
  @Prop item: string;

  aboutToAppear() {
    console.info(`[aboutToAppear]: item is ${this.item}`);
  }

  build() {
    Text(this.item)
      .fontSize(50)
  }
}
```

尽管本例中界面渲染结果符合预期，但在每次向数组中间插入新数组项时，ForEach会为该数组项及其后面的所有数组项重新创建组件。当数据源数据量较大或组件结构复杂时，组件无法复用会导致性能下降。因此，不建议省略第三个参数KeyGenerator函数，也不建议在键值中使用数据项索引index。

```typescript
//正确渲染并保证效率的ForEach写法
ForEach(this.simpleList, (item: string) => {
  ChildItem({ item: item })
}, (item: string) => item)  // 需要保证key唯一
```

### LazyForEach：数据懒加载

LazyForEach为开发者提供了基于数据源渲染出一系列子组件的能力。具体而言，LazyForEach从数据源中按需迭代数据，并在每次迭代时创建相应组件。当在滚动容器中使用了LazyForEach，框架会根据滚动容器可视区域按需创建组件，当组件滑出可视区域外时，框架会销毁并回收组件以降低内存占用。

### Repeat：可复用的循环渲染

Repeat基于数组类型数据来进行循环渲染，一般与容器组件配合使用。

Repeat根据容器组件的**有效加载范围**（屏幕可视区域+预加载区域）加载子组件。当容器滑动/数组改变时，Repeat会根据父容器组件的布局过程重新计算有效加载范围，并管理列表子组件节点的创建与销毁。

> 说明
>
> Repeat与LazyForEach组件的区别：
>
> - Repeat直接监听状态变量的变化，而LazyForEach需要开发者实现IDataSource接口，手动管理子组件内容/索引的修改。
> - Repeat还增强了节点复用能力，提高了长列表滑动和数据更新的渲染性能。
> - Repeat增加了渲染模板（template）的能力，在同一个数组中，根据开发者自定义的模板类型（template type）渲染不同的子组件。

## 设置组件导航和页面路由

### 组件导航

Navigation是路由导航的根视图容器，一般作为页面（@Entry）的根容器，包括单栏（Stack）、分栏（Split）和自适应（Auto）三种显示模式。

#### 设置页面显示模式

1. 自适应模式
2. 单栏模式
3. 分栏模式

#### 设置标题栏模式

1. Mini模式

   ```typescript
   Navigation() {
     // ...
   }
   .titleMode(NavigationTitleMode.Mini)
   ```

2. Full模式

   ```typescript
   Navigation() {
     // ...
   }
   .titleMode(NavigationTitleMode.Full)
   ```

#### 设置菜单栏

菜单栏位于Navigation组件的右上角

```typescript
let TooTmp: NavigationMenuItem = {'value': "", 'icon': "resources/base/media/ic_public_highlights.svg", 'action': ()=> {}}
Navigation() {
  // ...
}
.menus([TooTmp,
  TooTmp,
  TooTmp])
```

#### 设置工具栏

工具栏位于Navigation组件的底部

```typescript
let TooTmp: ToolbarItem = {'value': "func", 'icon': "./image/ic_public_highlights.svg", 'action': ()=> {}};
let TooBar: ToolbarItem[] = [TooTmp,TooTmp,TooTmp];
Navigation() {
  // ...
}
.toolbarConfiguration(TooBar)
```

#### 路由操作

##### 页面跳转

NavPathStack通过Push相关的接口去实现页面跳转的功能

1. 普通跳转 通过页面的name去跳转，并可以携带param

   ```typescript
   this.pageStack.pushPath({ name: "PageOne", param: "PageOne Param" });
   this.pageStack.pushPathByName("PageOne", "PageOne Param");
   ```

2. 带返回回调的跳转，跳转时添加onPop回调，能在页面出栈时获取返回信息，并进行处理。

   ```typescript
   this.pageStack.pushPathByName('PageOne', "PageOne Param", (popInfo) => {
     console.info('Pop page name is: ' + popInfo.info.name + ', result: ' + JSON.stringify(popInfo.result));
   });
   ```

3. 带错误码的跳转，跳转结束会触发异步回调，返回错误码信息。

   ```typescript
   this.pageStack.pushDestination({name: "PageOne", param: "PageOne Param"})
     .catch((error: BusinessError) => {
       console.error(`Push destination failed, error code = ${error.code}, error.message = ${error.message}.`);
     }).then(() => {
       console.info('Push destination succeed.');
     });
   this.pageStack.pushDestinationByName("PageOne", "PageOne Param")
     .catch((error: BusinessError) => {
       console.error(`Push destination failed, error code = ${error.code}, error.message = ${error.message}.`);
     }).then(() => {
       console.info('Push destination succeed.');
     });
   ```

##### 页面返回

NavPathStack通过Pop相关接口去实现页面返回功能。

```typescript
// 返回到上一页
this.pageStack.pop();
// 返回到上一个PageOne页面
this.pageStack.popToName("PageOne");
// 返回到索引为1的页面
this.pageStack.popToIndex(1);
// 返回到根首页（清除栈中所有页面）
this.pageStack.clear();
```

##### 页面替换

NavPathStack通过Replace相关接口去实现页面替换功能。

```typescript
// 将栈顶页面替换为PageOne
this.pageStack.replacePath({ name: "PageOne", param: "PageOne Param" });
this.pageStack.replacePathByName("PageOne", "PageOne Param");
// 带错误码的替换，跳转结束会触发异步回调，返回错误码信息
this.pageStack.replaceDestination({name: "PageOne", param: "PageOne Param"})
  .catch((error: BusinessError) => {
    console.error(`Replace destination failed, error code = ${error.code}, error.message = ${error.message}.`);
  }).then(() => {
    console.info('Replace destination succeed.');
  })
```

##### 页面删除

NavPathStack通过Remove相关接口去实现删除路由栈中特定页面的功能。

```typescript
// 删除栈中name为PageOne的所有页面
this.pageStack.removeByName("PageOne");
// 删除指定索引的页面
this.pageStack.removeByIndexes([1, 3, 5]);
// 删除指定id的页面
this.pageStack.removeByNavDestinationId("1");
```

##### 移动页面

```typescript
// 移动栈中name为PageOne的页面到栈顶
this.pageStack.moveToTop("PageOne");
// 移动栈中索引为1的页面到栈顶
this.pageStack.moveIndexToTop(1);
```

##### 参数获取

NavDestination子页第一次创建时会触发onReady回调，可以获取此页面对应的参数。

```typescript
@Component
struct Page01 {
  pathStack: NavPathStack | undefined = undefined;
  pageParam: string = '';

  build() {
    NavDestination() {
      // ...
    }.title('Page01')
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
      this.pageParam = context.pathInfo.param as string;
    })
  }
}
```

NavDestination组件中可以通过设置onResult接口，接收返回时传递的路由参数。

```typescript
class NavParam {
  desc: string = 'navigation-param'
}

@Component
struct DemoNavDestination {
  // ...
  build() {
    NavDestination() {
      // ...
    }
    .onResult((param: Object) => {
      if (param instanceof NavParam) {
        console.info('TestTag', 'get NavParam, its desc: ' + (param as NavParam).desc);
        return;
      }
      console.info('TestTag', 'param not instance of NavParam');
    })
  }
}
```

其他业务场景，可以通过主动调用NavPathStack的Get相关接口去获取指定页面的参数。

```typescript
// 获取栈中所有页面name集合
this.pageStack.getAllPathName();
// 获取索引为1的页面参数
this.pageStack.getParamByIndex(1);
// 获取PageOne页面的参数
this.pageStack.getParamByName("PageOne");
// 获取PageOne页面的索引集合
this.pageStack.getIndexByName("PageOne");
```

##### 路由拦截

NavPathStack提供了[setInterception](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-navigation#setinterception12)方法，用于设置Navigation页面跳转拦截回调。该方法需要传入一个NavigationInterception对象，该对象包含三个回调函数：

| 名称       | 描述                                                 |
| :--------- | :--------------------------------------------------- |
| willShow   | 页面跳转前回调，允许操作栈，在当前跳转生效。         |
| didShow    | 页面跳转后回调，在该回调中操作栈会在下一次跳转生效。 |
| modeChange | Navigation单双栏显示状态发生变更时触发该回调。       |

> [!Tip]
>
> 无论是哪个回调，在进入回调时路由栈都已经发生了变化。

可以在willShow回调中通过修改路由栈来实现路由拦截重定向的能力。

```typescript
this.pageStack.setInterception({
  willShow: (from: NavDestinationContext | "navBar", to: NavDestinationContext | "navBar",
    operation: NavigationOperation, animated: boolean) => {
    if (typeof to === "string") {
      console.info("target page is navigation home page.");
      return;
    }
    // 将跳转到PageTwo的路由重定向到PageOne
    let target: NavDestinationContext = to as NavDestinationContext;
    if (target.pathInfo.name === 'PageTwo') {
      target.pathStack.pop();
      target.pathStack.pushPathByName('PageOne', null);
    }
  }
})
```

#### 子页面

##### 页面显示类型

- 标准类型

  NavDestination组件默认为标准类型，此时mode属性为NavDestinationMode.STANDARD。标准类型的NavDestination的生命周期跟随其在NavPathStack路由栈中的位置变化而改变。

- 弹窗类型

  NavDestination设置mode为NavDestinationMode.DIALOG弹窗类型，此时整个NavDestination默认透明显示。弹窗类型的NavDestination显示和消失时不会影响下层标准类型的NavDestination的显示和生命周期，两者可以同时显示。

  ```typescript
  // Dialog NavDestination
  @Entry
  @Component
   struct Index {
     @Provide('NavPathStack') pageStack: NavPathStack = new NavPathStack();
  
     @Builder
     PagesMap(name: string) {
       if (name == 'DialogPage') {
         DialogPage();
       }
     }
  
     build() {
       Navigation(this.pageStack) {
         Button('Push DialogPage')
           .margin(20)
           .width('80%')
           .onClick(() => {
             this.pageStack.pushPathByName('DialogPage', '');
           })
       }
       .mode(NavigationMode.Stack)
       .title('Main')
       .navDestination(this.PagesMap)
     }
   }
  
   @Component
   export struct DialogPage {
     @Consume('NavPathStack') pageStack: NavPathStack;
  
     build() {
       NavDestination() {
         Stack({ alignContent: Alignment.Center }) {
           Column() {
             Text("Dialog NavDestination")
               .fontSize(20)
               .margin({ bottom: 100 })
             Button("Close").onClick(() => {
               this.pageStack.pop();
             }).width('30%')
           }
           .justifyContent(FlexAlign.Center)
           .backgroundColor(Color.White)
           .borderRadius(10)
           .height('30%')
           .width('80%')
         }.height("100%").width('100%')
       }
       .backgroundColor('rgba(0,0,0,0.5)')
       .hideTitleBar(true)
       .mode(NavDestinationMode.DIALOG)
     }
   }
  ```

##### 页面生命周期

略

##### 页面监听和查询

###### 页面信息查询

自定义组件提供queryNavDestinationInfo方法，可以在NavDestination内部查询到当前所属页面的信息，返回值为NavDestinationInfo，若查询不到则返回undefined。

```typescript
 import { uiObserver } from '@kit.ArkUI';

 // NavDestination内的自定义组件
 @Component
 struct MyComponent {
   navDesInfo: uiObserver.NavDestinationInfo | undefined;

   aboutToAppear(): void {
     this.navDesInfo = this.queryNavDestinationInfo();
   }

   build() {
       Column() {
         Text("所属页面Name: " + this.navDesInfo?.name)
       }.width('100%').height('100%')
   }
 }
```

###### 页面状态监听

通过observer.on('navDestinationUpdate')提供的注册接口可以注册NavDestination生命周期变化的监听，使用方式如下：

```typescript
uiObserver.on('navDestinationUpdate', (info) => {
     console.info('NavDestination state update', JSON.stringify(info));
 });
```

也可以注册页面切换的状态回调，能在页面发生路由切换的时候拿到对应的页面信息NavDestinationSwitchInfo，并且提供了UIAbilityContext和UIContext不同范围的监听：

```typescript
 // 在UIAbility中使用
 import { UIContext, uiObserver } from '@kit.ArkUI';

 // callbackFunc是开发者定义的监听回调函数
 function callbackFunc(info: uiObserver.NavDestinationSwitchInfo) {}
 uiObserver.on('navDestinationSwitch', this.context, callbackFunc);

 // 可以通过窗口的getUIContext()方法获取对应的UIContent
 uiContext: UIContext | null = null;
 uiObserver.on('navDestinationSwitch', this.uiContext, callbackFunc);
```

#### 页面转场

##### 关闭转场

1. 全局关闭
   Navigation通过NavPathStack中提供的disableAnimation方法可以在当前Navigation中关闭或打开所有转场动画。

   ```typescript
   pageStack: NavPathStack = new NavPathStack();
   
   aboutToAppear(): void {
     this.pageStack.disableAnimation(true);
   }
   ```

2. 单次关闭
   NavPathStack中提供的Push、Pop、Replace等接口中可以设置animated参数，默认为true表示有转场动画，需要单次关闭转场动画可以置为false，不影响下次转场动画。

   ```typescript
   pageStack: NavPathStack = new NavPathStack();
   
   this.pageStack.pushPath({ name: "PageOne" }, false);
   this.pageStack.pop(false);
   ```

##### 自定义转场

略

##### 共享元素转场

NavDestination之间切换时可以通过geometryTransition实现共享元素转场。配置了共享元素转场的页面同时需要关闭系统默认的转场动画。

1. 为需要实现共享元素转场的组件添加geometryTransition属性，id参数必须在两个NavDestination之间保持一致。

   ```typescript
   // 起始页配置共享元素id
   NavDestination() {
     Column() {
       // ...
       // $r('app.media.startIcon')需要替换为开发者所需的资源文件
       Image($r('app.media.startIcon'))
       .geometryTransition('sharedId')
       .width(100)
       .height(100)
     }
   }
   .title('FromPage')
   
   // 目的页配置共享元素id
   NavDestination() {
     Column() {
       // ...
       // $r('app.media.startIcon')需要替换为开发者所需的资源文件
       Image($r('app.media.startIcon'))
       .geometryTransition('sharedId')
       .width(200)
       .height(200)
     }
   }
   .title('ToPage')
   ```

2. 将页面路由的操作，放到animateTo动画闭包中，配置对应的动画参数以及关闭系统默认的转场。

   ```typescript
   NavDestination() {
     Column() {
       Button('跳转目的页')
       .width('80%')
       .height(40)
       .margin(20)
       .onClick(() => {
           this.getUIContext()?.animateTo({ duration: 1000 }, () => {
             this.pageStack.pushPath({ name: 'ToPage' }, false)
           });
       })
     }
   }
   .title('FromPage')
   ```

#### 跨包路由

系统提供**系统路由表**和**自定义路由表**两种实现方式。

- 系统路由表相对自定义路由表，使用更简单，只需要添加对应页面跳转配置项，即可实现页面跳转。
- 自定义路由表使用起来更复杂，但是可以根据应用业务进行定制处理。

支持自定义路由表和系统路由表混用。

##### 路由表能力对比

不同路由方式适用于不同需求，易用性或可扩展性需根据项目特点权衡选择。

| 路由方式                                                     | 跨包跳转能力                                 | 可扩展性       | 易用性                                 |
| :----------------------------------------------------------- | :------------------------------------------- | :------------- | :------------------------------------- |
| [系统路由表](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-navigation-navigation#系统路由表) | 跳转前无需import页面文件，页面按需动态加载。 | 可扩展性一般。 | 易用性更强，系统自动维护路由表。       |
| [自定义路由表](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-navigation-navigation#自定义路由表) | 跳转前需要import页面文件。                   | 可扩展性更强。 | 易用性一般，需要开发者自行维护路由表。 |

##### 系统路由表

1. 在跳转目标模块的配置文件[module.json5](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/module-configuration-file)添加路由表配置：

   ```typescript
     {
       "module" : {
         "routerMap": "$profile:route_map"
       }
     }
   ```

2. 添加完路由配置文件地址后，需要在工程resources/base/profile中创建route_map.json文件。添加如下配置信息：

   ```typescript
     {
       "routerMap": [
         {
           "name": "PageOne",
           "pageSourceFile": "src/main/ets/pages/PageOne.ets",
           "buildFunction": "PageOneBuilder",
           "data": {
             "description" : "this is PageOne"
           }
         }
       ]
     }
   ```

配置说明如下：

| 配置项         | 说明                                                         |
| :------------- | :----------------------------------------------------------- |
| name           | 可自定义的跳转页面名称。                                     |
| pageSourceFile | 跳转目标页在包内的路径，相对src目录的相对路径。              |
| buildFunction  | 跳转目标页的入口函数名称，必须以@Builder修饰。               |
| data           | 应用自定义字段。可以通过配置项读取接口getConfigInRouteMap获取。 |

3. 在跳转目标页面中，需要配置入口Builder函数，函数名称需要和route_map.json配置文件中的buildFunction保持一致，否则在编译时会报错。

   ```typescript
     // 跳转页面入口函数
     @Builder
     export function PageOneBuilder() {
       PageOne();
     }
   
     @Component
     struct PageOne {
       pathStack: NavPathStack = new NavPathStack();
   
       build() {
         NavDestination() {
         }
         .title('PageOne')
         .onReady((context: NavDestinationContext) => {
            this.pathStack = context.pathStack;
         })
       }
     }
   ```

4. 通过pushPathByName等路由接口进行页面跳转。(注意：此时Navigation中可以不用配置navDestination属性。)

   ```typescript
     @Entry
     @Component
     struct Index {
       pageStack : NavPathStack = new NavPathStack();
   
       build() {
         Navigation(this.pageStack){
         }.onAppear(() => {
           this.pageStack.pushPathByName("PageOne", null, false);
         })
         .hideNavBar(true)
       }
     }
   ```


##### 自定义路由表

自定义路由表通过给Navigation的[navDestination](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-navigation#navdestination10)属性设置Builder函数实现，其特点是需要import页面。有两种import页面的方式，静态import和动态import，二者的区别在于：

| import方式 | 模块间耦合度 | 实现复杂度 | 性能                                         |
| :--------- | :----------- | :--------- | :------------------------------------------- |
| 动态import | 模块间解耦。 | 复杂度高。 | 性能好，按需加载，跳转前再加载对应页面。     |
| 静态import | 模块间耦合。 | 复杂度低。 | 性能一般，初始化时一次性加载所有依赖的页面。 |

###### 动态import（推荐）

动态import旨在解决多个模块（HAR/HSP）能够复用相同的业务逻辑，实现各业务模块间的解耦，同时支持路由功能的扩展与整合，可以按需import，具体实现方法请参考考[Navigation自定义动态路由](https://gitee.com/harmonyos-cases/cases/blob/master/CommonAppDevelopment/common/routermodule/README_AUTO_GENERATE.md)示例

动态import的优势：

- 路由定义除了跳转的URL以外，可以配置丰富的扩展信息，如横竖屏默认模式、是否需要鉴权等等，做路由跳转时统一处理。
- 给每个路由页面设置一个名字，按照名称进行跳转而不是文件路径。
- 页面的加载可以使用动态import（按需加载），防止首个页面加载大量代码导致卡顿。

实现方案：

1. 定义页面跳转配置项。
   - 使用资源文件进行定义，通过资源管理@ohos.resourceManager在运行时对资源文件解析。
   - 在ets文件中配置路由加载配置项，一般包括路由页面名称（即pushPath等接口中页面的别名），文件所在模块名称（hsp/har的模块名），加载页面在模块内的路径（相对src目录的路径）。
2. 加载目标跳转页面，通过动态import将跳转目标页面所在的模块在运行时加载，在模块加载完成后，调用模块中的方法，通过import在模块的方法中加载模块中显示的目标页面，并返回页面加载完成后定义的Builder函数。
3. 触发页面跳转，在Navigation的navDestination属性执行步骤2中加载的Builder函数，即可跳转到目标页面。

###### 静态import

静态import实现方式简单，但通过静态import页面进行路由跳转会导致不同模块之间的依赖耦合，并增加首页加载时间长等问题

```typescript
import { pageOneTmp } from './pageOne';

@Entry
@Component
struct NavigationExample {
  @Provide('pageInfos') pageInfos: NavPathStack = new NavPathStack()
  private arr: number[] = [1, 2];

  @Builder
  pageMap(name: string) {
    if (name === "NavDestinationTitle1") {
      pageOneTmp();
    } else if (name === "NavDestinationTitle2") {
      pageTwoTmp();
    }
  }

  build() {
    Column() {
      Navigation(this.pageInfos) {
        TextInput({ placeholder: 'search...' })
          .width("90%")
          .height(40)

        List({ space: 12 }) {
          ForEach(this.arr, (item: number) => {
            ListItem() {
              Text("Page" + item)
                .width("100%")
                .height(72)
                .borderRadius(24)
                .fontSize(16)
                .fontWeight(500)
                .textAlign(TextAlign.Center)
                .onClick(() => {
                  this.pageInfos.pushPath({ name: "NavDestinationTitle" + item });
                })
            }
          }, (item: number) => item.toString())
        }
        .width("90%")
        .margin({ top: 12 })
      }
      .title("主标题")
      .navDestination(this.pageMap)
      .mode(NavigationMode.Split)
    }
    .height('100%')
    .width('100%')
  }
}

@Component
export struct pageTwoTmp {
  @Consume('pageInfos') pageInfos: NavPathStack;

  build() {
    NavDestination() {
      Column() {
        Text("NavDestinationContent2")
      }.width('100%').height('100%')
    }.title("NavDestinationTitle2")
    .onBackPressed(() => {
      const popDestinationInfo = this.pageInfos.pop(); // 弹出路由栈的栈顶元素
      console.info('pop' + '返回值' + JSON.stringify(popDestinationInfo));
      return true;
    })
  }
}

// pageOne.ets
@Component
export struct pageOneTmp {
  @Consume('pageInfos') pageInfos: NavPathStack;

  build() {
    NavDestination() {
      Column() {
        Text("NavDestinationContent1")
      }.width('100%').height('100%')
    }.title("NavDestinationTitle1")
    .onBackPressed(() => {
      const popDestinationInfo = this.pageInfos.pop(); // 弹出路由栈的栈顶元素
      console.info('pop' + '返回值' + JSON.stringify(popDestinationInfo));
      return true;
    })
  }
}
```

#### 页面路由

##### 页面跳转

Router模块提供了两种跳转模式，分别是pushUrl和replaceUrl。这两种模式决定了目标页面是否会替换当前页。

- pushUrl：目标页面不会替换当前页，而是压入页面栈。这样可以保留当前页的状态，并且可以通过返回键或者调用back方法返回到当前页。
- replaceUrl：目标页面会替换当前页，并销毁当前页。这样可以释放当前页的资源，并且无法返回到当前页。

