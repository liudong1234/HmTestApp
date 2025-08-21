@ObservedV2
class Info {
  @Trace name: string = '';
  @Trace age: number = 0;
}

@ComponentV2
struct ChildPage {
  @Require @Param childInfo: Info;

  build() {
    Column() {
      Text(`自定义组件 name :${this.childInfo.name}`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Text(`自定义组件 age :${this.childInfo.age}`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
    }
  }
}

@Entry
@ComponentV2
struct ParentPage {
  info1: Info = { name: "Tom", age: 25 };
  @Local info2: Info = { name: "Tom", age: 25 };

  @LocalBuilder
  privateBuilder() {
    Column() {
      Text(`局部LocalBuilder@Builder name :${this.info1.name}`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Text(`局部LocalBuilder@Builder age :${this.info1.age}`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
    }
  }

  @LocalBuilder
  privateBuilderSecond() {
    Column() {
      Text(`局部LocalBuilder@Builder name :${this.info2.name}`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
      Text(`局部LocalBuilder@Builder age :${this.info2.age}`)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
    }
  }

  build() {
    Column() {
      Text(`info1: ${this.info1.name}  ${this.info1.age}`) // Text1
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
      this.privateBuilder() // 调用局部@Builder
      Line()
        .width('100%')
        .height(10)
        .backgroundColor('#000000').margin(10)
      Text(`info2: ${this.info2.name}  ${this.info2.age}`) // Text2
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
      this.privateBuilderSecond() // 调用局部@Builder
      Line()
        .width('100%')
        .height(10)
        .backgroundColor('#000000').margin(10)
      Text(`info1: ${this.info1.name}  ${this.info1.age}`) // Text1
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
      ChildPage({ childInfo: this.info1 }) // 调用自定义组件
      Line()
        .width('100%')
        .height(10)
        .backgroundColor('#000000').margin(10)
      Text(`info2: ${this.info2.name}  ${this.info2.age}`) // Text2
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
      ChildPage({ childInfo: this.info2 }) // 调用自定义组件
      Line()
        .width('100%')
        .height(10)
        .backgroundColor('#000000').margin(10)
      Button("change info1&info2")
        .onClick(() => {
          this.info1 = { name: "Cat", age: 18 }; // Text1不会刷新，原因是info1没被装饰器装饰，无法监听到值的改变。
          this.info2 = { name: "Cat", age: 18 }; // Text2会刷新，原因是info2有装饰器装饰，可以监听到值的改变。
        })
    }
  }
}