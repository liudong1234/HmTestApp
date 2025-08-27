# 学习开发笔记

## UI范式

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

